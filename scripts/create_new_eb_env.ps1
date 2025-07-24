# Create New Elastic Beanstalk Environment using AWS CLI
Write-Host "Creating new Elastic Beanstalk environment..." -ForegroundColor Green

# Set environment name
$ENV_NAME = "tubby-backend-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$DEPLOY_DIR = "deploy-new-env"
if (Test-Path $DEPLOY_DIR) { Remove-Item $DEPLOY_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $DEPLOY_DIR | Out-Null

# Copy files
Copy-Item "backend/eb_working_app.py" "$DEPLOY_DIR/"
Copy-Item "backend/requirements_simple.txt" "$DEPLOY_DIR/requirements.txt"
Copy-Item "backend/Procfile_eb" "$DEPLOY_DIR/Procfile"

# Create .ebextensions directory and copy config
New-Item -ItemType Directory -Path "$DEPLOY_DIR/.ebextensions" | Out-Null
Copy-Item "backend/.ebextensions/01_flask.config" "$DEPLOY_DIR/.ebextensions/"

# Navigate to deploy directory
Set-Location $DEPLOY_DIR

Write-Host "Creating ZIP file..." -ForegroundColor Yellow
$ZIP_FILE = "app-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
Compress-Archive -Path * -DestinationPath $ZIP_FILE

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
    $VERSION_LABEL = "v-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    aws elasticbeanstalk create-application-version --application-name tubby-backend --version-label $VERSION_LABEL --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE --region us-east-1
    
    # Create new environment
    Write-Host "Creating new environment: $ENV_NAME" -ForegroundColor Yellow
    aws elasticbeanstalk create-environment --application-name tubby-backend --environment-name $ENV_NAME --version-label $VERSION_LABEL --solution-stack-name "64bit Amazon Linux 2023 v4.6.1 running Python 3.11" --option-settings Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=t2.micro --region us-east-1
    
    Write-Host "Environment creation initiated!" -ForegroundColor Green
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