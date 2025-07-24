# Deploy to Elastic Beanstalk using AWS CLI only
Write-Host "Deploying to Elastic Beanstalk using AWS CLI only..." -ForegroundColor Green

# Set environment name
$ENV_NAME = "tubbyai-env-1"

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$DEPLOY_DIR = "deploy-aws-cli"
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
    
    # Upload to S3
    Write-Host "Uploading to S3: s3://$BUCKET/$ZIP_FILE" -ForegroundColor Yellow
    aws s3 cp $ZIP_FILE "s3://$BUCKET/$ZIP_FILE"
    
    # Create application version
    Write-Host "Creating application version..." -ForegroundColor Yellow
    $VERSION_LABEL = "v-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    aws elasticbeanstalk create-application-version --application-name tubby-backend --version-label $VERSION_LABEL --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE
    
    # Update environment
    Write-Host "Updating environment: $ENV_NAME" -ForegroundColor Yellow
    aws elasticbeanstalk update-environment --environment-name $ENV_NAME --version-label $VERSION_LABEL
    
    Write-Host "Deployment initiated successfully!" -ForegroundColor Green
    Write-Host "Version: $VERSION_LABEL" -ForegroundColor Cyan
    
    # Wait a moment and check status
    Write-Host "Waiting for deployment to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Get environment status
    Write-Host "Checking environment status..." -ForegroundColor Yellow
    $ENV_INFO = aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --query 'Environments[0]' --output json | ConvertFrom-Json
    
    Write-Host "Status: $($ENV_INFO.Status)" -ForegroundColor Cyan
    Write-Host "Health: $($ENV_INFO.Health)" -ForegroundColor Cyan
    Write-Host "URL: http://$($ENV_INFO.CNAME)" -ForegroundColor Green
    
    if ($ENV_INFO.Status -eq "Updating") {
        Write-Host "Environment is updating. Check AWS Console for progress." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check AWS Console for details" -ForegroundColor Yellow
}

# Go back to original directory
Set-Location ..

# Cleanup
Remove-Item $DEPLOY_DIR -Recurse -Force -ErrorAction SilentlyContinue 