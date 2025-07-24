# Deploy to Elastic Beanstalk using AWS CLI
Write-Host "Deploying to Elastic Beanstalk using AWS CLI..." -ForegroundColor Green

# Set environment name
$ENV_NAME = "tubbyai-env-1"

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$DEPLOY_DIR = "deploy-eb-cli"
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

Write-Host "Deploying using EB CLI..." -ForegroundColor Green
try {
    # Initialize EB application if needed
    Write-Host "Initializing EB application..." -ForegroundColor Yellow
    eb init tubby-backend --platform python-3.11 --region us-east-1 --force
    
    # Deploy to existing environment
    Write-Host "Deploying to environment: $ENV_NAME" -ForegroundColor Yellow
    eb deploy $ENV_NAME
    
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    
    # Get environment status
    Write-Host "Getting environment status..." -ForegroundColor Yellow
    $STATUS = eb status $ENV_NAME
    Write-Host "Status: $STATUS" -ForegroundColor Cyan
    
    # Get the URL
    $ENV_INFO = aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --query 'Environments[0].CNAME' --output text
    Write-Host "URL: http://$ENV_INFO" -ForegroundColor Green
    
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Trying alternative approach..." -ForegroundColor Yellow
    
    # Try manual deployment using AWS CLI
    try {
        Write-Host "Creating application version..." -ForegroundColor Yellow
        $ZIP_FILE = "app-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
        Compress-Archive -Path * -DestinationPath $ZIP_FILE
        
        # Get S3 bucket
        $ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
        $BUCKET = "elasticbeanstalk-us-east-1-$ACCOUNT_ID"
        
        Write-Host "Uploading to S3: s3://$BUCKET/$ZIP_FILE" -ForegroundColor Yellow
        aws s3 cp $ZIP_FILE "s3://$BUCKET/$ZIP_FILE"
        
        Write-Host "Creating application version..." -ForegroundColor Yellow
        $VERSION_LABEL = "v-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        aws elasticbeanstalk create-application-version --application-name tubby-backend --version-label $VERSION_LABEL --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE
        
        Write-Host "Updating environment..." -ForegroundColor Yellow
        aws elasticbeanstalk update-environment --environment-name $ENV_NAME --version-label $VERSION_LABEL
        
        Write-Host "Manual deployment completed!" -ForegroundColor Green
        
    } catch {
        Write-Host "Manual deployment also failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Go back to original directory
Set-Location ..

# Cleanup
Remove-Item $DEPLOY_DIR -Recurse -Force -ErrorAction SilentlyContinue 