# Create Unix-compatible ZIP using 7-Zip
Write-Host "Creating Unix-compatible ZIP using 7-Zip..." -ForegroundColor Green

# Check if 7-Zip is available
$7ZIP_PATH = "C:\Program Files\7-Zip\7z.exe"
if (-not (Test-Path $7ZIP_PATH)) {
    Write-Host "7-Zip not found at: $7ZIP_PATH" -ForegroundColor Red
    Write-Host "Please install 7-Zip from: https://7-zip.org/" -ForegroundColor Yellow
    Write-Host "Or download portable version and place 7z.exe in the project directory" -ForegroundColor Yellow
    exit 1
}

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$DEPLOY_DIR = "unix-deploy"
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

# Navigate to deploy directory
Set-Location $DEPLOY_DIR

Write-Host "Creating Unix-compatible ZIP with 7-Zip..." -ForegroundColor Yellow
$ZIP_FILE = "unix-hello-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"

# Use 7-Zip to create Unix-compatible ZIP
& $7ZIP_PATH a -tzip $ZIP_FILE * -mx=9

Write-Host "ZIP file created: $ZIP_FILE" -ForegroundColor Green
Write-Host "Files included:" -ForegroundColor Yellow
Get-ChildItem -Recurse | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Cyan }

# Get account ID and S3 bucket
Write-Host "Getting AWS account info..." -ForegroundColor Yellow
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$BUCKET = "elasticbeanstalk-us-east-1-$ACCOUNT_ID"

Write-Host "Account ID: $ACCOUNT_ID" -ForegroundColor Cyan
Write-Host "S3 Bucket: $BUCKET" -ForegroundColor Cyan

# Upload to S3
Write-Host "Uploading to S3: s3://$BUCKET/$ZIP_FILE" -ForegroundColor Yellow
aws s3 cp $ZIP_FILE "s3://$BUCKET/$ZIP_FILE" --region us-east-1

# Create application version
Write-Host "Creating application version..." -ForegroundColor Yellow
$VERSION_LABEL = "unix-v-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
aws elasticbeanstalk create-application-version --application-name tubbyai --version-label $VERSION_LABEL --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE --region us-east-1

# Create new environment
Write-Host "Creating new environment..." -ForegroundColor Yellow
$ENV_NAME = "tubby-unix-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

aws elasticbeanstalk create-environment --application-name tubbyai --environment-name $ENV_NAME --version-label $VERSION_LABEL --solution-stack-name "64bit Amazon Linux 2023 v4.6.1 running Python 3.11" --option-settings "Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=t2.micro" --region us-east-1

Write-Host "Unix-compatible environment creation initiated!" -ForegroundColor Green
Write-Host "Environment: $ENV_NAME" -ForegroundColor Cyan
Write-Host "Version: $VERSION_LABEL" -ForegroundColor Cyan

# Wait and check status
Write-Host "Waiting for environment to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Get environment status
Write-Host "Checking environment status..." -ForegroundColor Yellow
$ENV_INFO = aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --region us-east-1 --query 'Environments[0]' --output json | ConvertFrom-Json

Write-Host "Status: $($ENV_INFO.Status)" -ForegroundColor Cyan
Write-Host "Health: $($ENV_INFO.Health)" -ForegroundColor Cyan
Write-Host "URL: http://$($ENV_INFO.CNAME)" -ForegroundColor Green

# Go back to original directory
Set-Location ..

# Cleanup
Remove-Item $DEPLOY_DIR -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "If 7-Zip is not installed, you can:" -ForegroundColor Yellow
Write-Host "1. Download from: https://7-zip.org/" -ForegroundColor Cyan
Write-Host "2. Or use the manual ZIP we created: console-upload\console-hello.zip" -ForegroundColor Cyan
Write-Host "3. Upload it manually through AWS Console" -ForegroundColor Cyan 