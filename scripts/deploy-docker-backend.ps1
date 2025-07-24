# Docker-based Backend Deployment for TubbyAI
param(
    [string]$Environment = "development"
)

Write-Host "TubbyAI Docker Backend Deployment" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Configuration
$PROJECT_ROOT = $PSScriptRoot | Split-Path
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"

# Check Docker
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "Docker found: $dockerVersion" -ForegroundColor Green
    } else {
        Write-Host "Docker not found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Docker not available" -ForegroundColor Red
    exit 1
}

# Check AWS CLI
try {
    $awsVersion = aws --version 2>$null
    if ($awsVersion) {
        Write-Host "AWS CLI found: $awsVersion" -ForegroundColor Green
    } else {
        Write-Host "AWS CLI not found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "AWS CLI not available" -ForegroundColor Red
    exit 1
}

# Create Docker deployment package
Write-Host "Creating Docker deployment package..." -ForegroundColor Yellow

# Create temporary directory
$TEMP_DIR = Join-Path $PROJECT_ROOT "docker-deploy-$TIMESTAMP"
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

# Copy backend files
Write-Host "  Copying backend files..." -ForegroundColor Cyan
Copy-Item "$BACKEND_DIR\*.py" $TEMP_DIR -ErrorAction SilentlyContinue
Copy-Item "$BACKEND_DIR\requirements*.txt" $TEMP_DIR -ErrorAction SilentlyContinue
Copy-Item "$BACKEND_DIR\Procfile*" $TEMP_DIR -ErrorAction SilentlyContinue
Copy-Item "$BACKEND_DIR\gunicorn.conf.py" $TEMP_DIR -ErrorAction SilentlyContinue

# Copy .ebextensions if exists
if (Test-Path "$BACKEND_DIR\.ebextensions") {
    Copy-Item "$BACKEND_DIR\.ebextensions" $TEMP_DIR -Recurse
}

# Create Dockerfile for deployment
$DOCKERFILE_CONTENT = @'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements*.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create ZIP file with Unix paths
RUN apt-get update && apt-get install -y zip
RUN zip -r /tmp/tubby-backend.zip . -x "*.git*" "*.pyc" "__pycache__/*" "tests/*"

# Copy ZIP to host
CMD ["cp", "/tmp/tubby-backend.zip", "/output/"]
'@

$DOCKERFILE_CONTENT | Out-File -FilePath (Join-Path $TEMP_DIR "Dockerfile.deploy") -Encoding UTF8

# Build Docker image and create ZIP
Write-Host "  Building Docker image..." -ForegroundColor Cyan
Set-Location $TEMP_DIR

# Create output directory
New-Item -ItemType Directory -Path "output" -Force | Out-Null

# Build and run Docker container
try {
    docker build -f Dockerfile.deploy -t tubby-deploy:$TIMESTAMP .
    docker run --rm -v "${TEMP_DIR}/output:/output" tubby-deploy:$TIMESTAMP
    
    # Check if ZIP was created
    $ZIP_FILE = Get-ChildItem "output/tubby-backend.zip" -ErrorAction SilentlyContinue
    if ($ZIP_FILE) {
        Write-Host "  Docker ZIP created successfully" -ForegroundColor Green
        Copy-Item $ZIP_FILE.FullName (Join-Path $PROJECT_ROOT "tubby-backend-docker-$TIMESTAMP.zip")
    } else {
        Write-Host "Failed to create ZIP file" -ForegroundColor Red
        Set-Location $PROJECT_ROOT
        Remove-Item $TEMP_DIR -Recurse -Force
        exit 1
    }
} catch {
    Write-Host "Docker build failed: $($_.Exception.Message)" -ForegroundColor Red
    Set-Location $PROJECT_ROOT
    Remove-Item $TEMP_DIR -Recurse -Force
    exit 1
}

# Deploy to Elastic Beanstalk
Write-Host "Deploying to Elastic Beanstalk..." -ForegroundColor Yellow

try {
    Set-Location $PROJECT_ROOT
    
    # Get AWS account info
    $ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
    $BUCKET = "elasticbeanstalk-us-east-1-$ACCOUNT_ID"
    $ZIP_FILE_NAME = "tubby-backend-docker-$TIMESTAMP.zip"
    
    Write-Host "  Account ID: $ACCOUNT_ID" -ForegroundColor Cyan
    Write-Host "  S3 Bucket: $BUCKET" -ForegroundColor Cyan
    
    # Upload to S3
    Write-Host "  Uploading to S3..." -ForegroundColor Cyan
    aws s3 cp $ZIP_FILE_NAME "s3://$BUCKET/$ZIP_FILE_NAME" --region us-east-1
    
    # Create application version
    Write-Host "  Creating application version..." -ForegroundColor Cyan
    $VERSION_LABEL = "docker-v-$TIMESTAMP"
    aws elasticbeanstalk create-application-version --application-name tubbyai --version-label $VERSION_LABEL --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE_NAME --region us-east-1
    
    # Deploy to environment
    Write-Host "  Deploying to environment..." -ForegroundColor Cyan
    $ENV_NAME = "tubby-docker-$Environment-$TIMESTAMP"
    
    aws elasticbeanstalk create-environment --application-name tubbyai --environment-name $ENV_NAME --version-label $VERSION_LABEL --solution-stack-name "64bit Amazon Linux 2023 v4.6.1 running Python 3.11" --option-settings "Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=t2.micro" --region us-east-1
    
    Write-Host "  Docker deployment initiated!" -ForegroundColor Green
    Write-Host "  Environment: $ENV_NAME" -ForegroundColor Cyan
    Write-Host "  Version: $VERSION_LABEL" -ForegroundColor Cyan
    
    # Wait and check status
    Write-Host "  Waiting for environment to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Get environment status
    Write-Host "  Checking environment status..." -ForegroundColor Cyan
    $ENV_INFO = aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --region us-east-1 --query 'Environments[0]' --output json | ConvertFrom-Json
    
    Write-Host "  Status: $($ENV_INFO.Status)" -ForegroundColor Cyan
    Write-Host "  Health: $($ENV_INFO.Health)" -ForegroundColor Cyan
    if ($ENV_INFO.CNAME) {
        Write-Host "  URL: http://$($ENV_INFO.CNAME)" -ForegroundColor Green
    }
    
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup
    Remove-Item $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ZIP_FILE_NAME -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Docker deployment complete!" -ForegroundColor Green 