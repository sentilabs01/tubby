# Create Manual Unix-compatible ZIP
Write-Host "Creating manual Unix-compatible ZIP..." -ForegroundColor Green

# Set environment name
$ENV_NAME = "tubby-manual-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$DEPLOY_DIR = "deploy-manual"
if (Test-Path $DEPLOY_DIR) { Remove-Item $DEPLOY_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $DEPLOY_DIR | Out-Null

# Copy files with Unix-style paths
Write-Host "Copying files..." -ForegroundColor Yellow
Copy-Item "backend/hello_world.py" "$DEPLOY_DIR/hello_world.py"
Copy-Item "backend/requirements_simple.txt" "$DEPLOY_DIR/requirements.txt"
Copy-Item "backend/Procfile_hello" "$DEPLOY_DIR/Procfile"

# Create .ebextensions directory
New-Item -ItemType Directory -Path "$DEPLOY_DIR/.ebextensions" | Out-Null
Copy-Item "backend/.ebextensions/02_hello.config" "$DEPLOY_DIR/.ebextensions/02_hello.config"

# Navigate to deploy directory
Set-Location $DEPLOY_DIR

Write-Host "Creating manual ZIP file..." -ForegroundColor Yellow
$ZIP_FILE = "manual-hello-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"

# Try to use 7-Zip if available
$7ZIP_PATH = "C:\Program Files\7-Zip\7z.exe"
if (Test-Path $7ZIP_PATH) {
    Write-Host "Using 7-Zip for Unix-compatible ZIP..." -ForegroundColor Green
    & $7ZIP_PATH a -tzip $ZIP_FILE * -mx=9
} else {
    Write-Host "7-Zip not found. Trying alternative approach..." -ForegroundColor Yellow
    
    # Try to use WinRAR if available
    $WINRAR_PATH = "C:\Program Files\WinRAR\WinRAR.exe"
    if (Test-Path $WINRAR_PATH) {
        Write-Host "Using WinRAR for Unix-compatible ZIP..." -ForegroundColor Green
        & $WINRAR_PATH a -afzip -r $ZIP_FILE *
    } else {
        Write-Host "No suitable ZIP tool found. Using PowerShell..." -ForegroundColor Yellow
        Compress-Archive -Path * -DestinationPath $ZIP_FILE -Force
    }
}

try {
    # Get account ID and S3 bucket
    Write-Host "Getting AWS account info..." -ForegroundColor Yellow
    $ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
    $BUCKET = "elasticbeanstalk-us-east-1-$ACCOUNT_ID"
    
    Write-Host "Account ID: $ACCOUNT_ID" -ForegroundColor Cyan
    Write-Host "S3 Bucket: $BUCKET" -ForegroundColor Cyan
    Write-Host "Environment Name: $ENV_NAME" -ForegroundColor Cyan
    
    # Upload to S3 with region specification
    Write-Host "Uploading to S3: s3://$BUCKET/$ZIP_FILE" -ForegroundColor Yellow
    aws s3 cp $ZIP_FILE "s3://$BUCKET/$ZIP_FILE" --region us-east-1
    
    # Create application version
    Write-Host "Creating application version..." -ForegroundColor Yellow
    $VERSION_LABEL = "manual-v-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    aws elasticbeanstalk create-application-version --application-name tubby-backend --version-label $VERSION_LABEL --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE --region us-east-1
    
    # Create new environment with IAM configuration
    Write-Host "Creating new environment: $ENV_NAME" -ForegroundColor Yellow
    
    # Create environment with proper IAM settings
    aws elasticbeanstalk create-environment --application-name tubby-backend --environment-name $ENV_NAME --version-label $VERSION_LABEL --solution-stack-name "64bit Amazon Linux 2023 v4.6.1 running Python 3.11" --option-settings "Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=t2.micro" "Namespace=aws:elasticbeanstalk:environment,OptionName=ServiceRole,Value=aws-elasticbeanstalk-service-role" "Namespace=aws:autoscaling:launchconfiguration,OptionName=IamInstanceProfile,Value=aws-elasticbeanstalk-ec2-role" --region us-east-1
    
    Write-Host "Manual environment creation initiated!" -ForegroundColor Green
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
    
    if ($ENV_INFO.Status -eq "Launching") {
        Write-Host "Environment is launching. This may take 5-10 minutes." -ForegroundColor Yellow
        Write-Host "Check AWS Console for progress." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Environment creation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check AWS Console for details" -ForegroundColor Yellow
}

# Go back to original directory
Set-Location ..

# Cleanup
Remove-Item $DEPLOY_DIR -Recurse -Force -ErrorAction SilentlyContinue 