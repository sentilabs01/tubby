# Minimal Deployment - Uses EB defaults
param(
    [string]$Environment = "Tubbyai-env-1"
)

Write-Host "TubbyAI Minimal Deployment" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

# Configuration
$PROJECT_ROOT = $PSScriptRoot | Split-Path
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"

# Check prerequisites
try {
    $dockerVersion = docker --version 2>$null
    $awsVersion = aws --version 2>$null
    Write-Host "Docker: $dockerVersion" -ForegroundColor Green
    Write-Host "AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "Prerequisites check failed" -ForegroundColor Red
    exit 1
}

# Create deployment package
Write-Host "Creating minimal deployment package..." -ForegroundColor Yellow

$TEMP_DIR = Join-Path $PROJECT_ROOT "minimal-deploy-$TIMESTAMP"
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

# Copy only the essential files
Write-Host "  Copying essential files..." -ForegroundColor Cyan
Copy-Item "$BACKEND_DIR\application.py" $TEMP_DIR
Copy-Item "$BACKEND_DIR\requirements_simple.txt" "$TEMP_DIR\requirements.txt"

# Create Dockerfile
$DOCKERFILE_CONTENT = @'
FROM python:3.13-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create ZIP file with Unix paths
RUN zip -r /tmp/tubby-minimal.zip . -x "*.git*" "*.pyc" "__pycache__/*"

# Copy ZIP to host
CMD ["cp", "/tmp/tubby-minimal.zip", "/output/"]
'@

$DOCKERFILE_CONTENT | Out-File -FilePath (Join-Path $TEMP_DIR "Dockerfile") -Encoding UTF8

# Build and create ZIP
Write-Host "  Building Docker image..." -ForegroundColor Cyan
Set-Location $TEMP_DIR
New-Item -ItemType Directory -Path "output" -Force | Out-Null

try {
    docker build -t tubby-minimal:$TIMESTAMP .
    docker run --rm -v "${TEMP_DIR}/output:/output" tubby-minimal:$TIMESTAMP
    
    $ZIP_FILE = Get-ChildItem "output/tubby-minimal.zip" -ErrorAction SilentlyContinue
    if ($ZIP_FILE) {
        Write-Host "  ZIP created successfully" -ForegroundColor Green
        Copy-Item $ZIP_FILE.FullName (Join-Path $PROJECT_ROOT "tubby-minimal-$TIMESTAMP.zip")
    } else {
        throw "ZIP file not created"
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
    
    $ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
    $BUCKET = "elasticbeanstalk-us-east-1-$ACCOUNT_ID"
    $ZIP_FILE_NAME = "tubby-minimal-$TIMESTAMP.zip"
    
    Write-Host "  Account ID: $ACCOUNT_ID" -ForegroundColor Cyan
    Write-Host "  S3 Bucket: $BUCKET" -ForegroundColor Cyan
    
    # Upload to S3
    Write-Host "  Uploading to S3..." -ForegroundColor Cyan
    aws s3 cp $ZIP_FILE_NAME "s3://$BUCKET/$ZIP_FILE_NAME" --region us-east-1
    
    # Create application version
    Write-Host "  Creating application version..." -ForegroundColor Cyan
    $VERSION_LABEL = "minimal-v-$TIMESTAMP"
    aws elasticbeanstalk create-application-version --application-name tubbyai --version-label $VERSION_LABEL --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE_NAME --region us-east-1
    
    # Update existing environment
    Write-Host "  Updating environment: $Environment" -ForegroundColor Cyan
    aws elasticbeanstalk update-environment --environment-name $Environment --version-label $VERSION_LABEL --region us-east-1
    
    Write-Host "  Deployment initiated!" -ForegroundColor Green
    Write-Host "  Environment: $Environment" -ForegroundColor Cyan
    Write-Host "  Version: $VERSION_LABEL" -ForegroundColor Cyan
    
    # Wait and check status
    Write-Host "  Waiting for environment to update..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
    
    # Get environment status
    Write-Host "  Checking environment status..." -ForegroundColor Cyan
    $ENV_INFO = aws elasticbeanstalk describe-environments --environment-names $Environment --region us-east-1 --query 'Environments[0]' --output json | ConvertFrom-Json
    
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
Write-Host "Minimal deployment complete!" -ForegroundColor Green 