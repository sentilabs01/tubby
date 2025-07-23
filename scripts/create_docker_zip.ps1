# Create Unix-compatible ZIP using Docker
Write-Host "Creating Unix-compatible ZIP using Docker..." -ForegroundColor Green

# Check if Docker is available
try {
    docker --version | Out-Null
    Write-Host "Docker found!" -ForegroundColor Green
} catch {
    Write-Host "Docker not found. Trying alternative approach..." -ForegroundColor Yellow
    exit 1
}

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$DEPLOY_DIR = "docker-deploy"
if (Test-Path $DEPLOY_DIR) { Remove-Item $DEPLOY_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $DEPLOY_DIR | Out-Null

# Copy files
Write-Host "Copying files..." -ForegroundColor Yellow
Copy-Item "backend/hello_world.py" "$DEPLOY_DIR/"
Copy-Item "backend/requirements_simple.txt" "$DEPLOY_DIR/requirements.txt"
Copy-Item "backend/Procfile_hello" "$DEPLOY_DIR/Procfile"

# Create .ebextensions directory
New-Item -ItemType Directory -Path "$DEPLOY_DIR/.ebextensions" | Out-Null
Copy-Item "backend/.ebextensions/02_hello.config" "$DEPLOY_DIR/.ebextensions/"

# Create Dockerfile for ZIP creation
$DOCKERFILE = @"
FROM alpine:latest
RUN apk add --no-cache zip
WORKDIR /app
COPY . .
RUN zip -r app.zip . -x "*.git*" "*.DS_Store*"
CMD ["cat", "app.zip"]
"@

$DOCKERFILE | Out-File -FilePath "$DEPLOY_DIR/Dockerfile" -Encoding UTF8

Write-Host "Building Docker image and creating ZIP..." -ForegroundColor Yellow
Set-Location $DEPLOY_DIR

# Build Docker image and extract ZIP
docker build -t zip-creator . | Out-Null
docker run --rm zip-creator > ../docker-hello.zip

Set-Location ..

Write-Host "Docker ZIP created: docker-hello.zip" -ForegroundColor Green

# Get account ID and S3 bucket
Write-Host "Getting AWS account info..." -ForegroundColor Yellow
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$BUCKET = "elasticbeanstalk-us-east-1-$ACCOUNT_ID"

Write-Host "Account ID: $ACCOUNT_ID" -ForegroundColor Cyan
Write-Host "S3 Bucket: $BUCKET" -ForegroundColor Cyan

# Upload to S3
Write-Host "Uploading to S3..." -ForegroundColor Yellow
$ZIP_FILE = "docker-hello-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
aws s3 cp docker-hello.zip "s3://$BUCKET/$ZIP_FILE" --region us-east-1

# Create application version
Write-Host "Creating application version..." -ForegroundColor Yellow
$VERSION_LABEL = "docker-v-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
aws elasticbeanstalk create-application-version --application-name tubbyai --version-label $VERSION_LABEL --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE --region us-east-1

# Create new environment
Write-Host "Creating new environment..." -ForegroundColor Yellow
$ENV_NAME = "tubby-docker-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

aws elasticbeanstalk create-environment --application-name tubbyai --environment-name $ENV_NAME --version-label $VERSION_LABEL --solution-stack-name "64bit Amazon Linux 2023 v4.6.1 running Python 3.11" --option-settings "Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=t2.micro" --region us-east-1

Write-Host "Docker-based environment creation initiated!" -ForegroundColor Green
Write-Host "Environment: $ENV_NAME" -ForegroundColor Cyan
Write-Host "Version: $VERSION_LABEL" -ForegroundColor Cyan

# Cleanup
Remove-Item $DEPLOY_DIR -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item docker-hello.zip -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Docker ZIP file also available for manual upload: docker-hello.zip" -ForegroundColor Green 