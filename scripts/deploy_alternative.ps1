# Alternative Deployment Script
Write-Host "Trying alternative deployment approach..." -ForegroundColor Green

# Set environment name
$ENV_NAME = "tubby-alt-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$DEPLOY_DIR = "deploy-alt"
if (Test-Path $DEPLOY_DIR) { Remove-Item $DEPLOY_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $DEPLOY_DIR | Out-Null

# Copy ultra minimal files
Copy-Item "backend/ultra_minimal_test.py" "$DEPLOY_DIR/"
Copy-Item "backend/requirements_ultra_minimal.txt" "$DEPLOY_DIR/requirements.txt"
Copy-Item "backend/Procfile_ultra_minimal" "$DEPLOY_DIR/Procfile"

# Create .ebextensions with alternative configuration
New-Item -ItemType Directory -Path "$DEPLOY_DIR/.ebextensions" | Out-Null

# Alternative configuration
@"
option_settings:
  aws:elasticbeanstalk:container:python:
    WSGIPath: ultra_minimal_test:app
  aws:autoscaling:launchconfiguration:
    InstanceType: t2.micro
  aws:elasticbeanstalk:environment:
    EnvironmentType: SingleInstance
"@ | Out-File -FilePath "$DEPLOY_DIR/.ebextensions/01_config.config" -Encoding UTF8

# Navigate to deploy directory
Set-Location $DEPLOY_DIR

Write-Host "Deploying with alternative configuration..." -ForegroundColor Green
try {
    # Initialize EB application with different region
    eb init tubby-backend --platform python-3.11 --region us-west-2
    
    # Create environment
    eb create $ENV_NAME
    
    Write-Host "Alternative deployment completed!" -ForegroundColor Green
    Write-Host "Environment: $ENV_NAME" -ForegroundColor Cyan
    
} catch {
    Write-Host "Alternative deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Trying manual AWS CLI deployment..." -ForegroundColor Yellow
    
    # Try manual deployment using AWS CLI
    try {
        # Create application version
        $ZIP_FILE = "app-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
        Compress-Archive -Path * -DestinationPath $ZIP_FILE
        
        # Upload to S3
        $BUCKET = "elasticbeanstalk-us-west-2-$(aws sts get-caller-identity --query Account --output text)"
        aws s3 cp $ZIP_FILE "s3://$BUCKET/$ZIP_FILE"
        
        # Create application version
        aws elasticbeanstalk create-application-version --application-name tubby-backend --version-label "v-$(Get-Date -Format 'yyyyMMdd-HHmmss')" --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE
        
        Write-Host "Manual deployment attempted!" -ForegroundColor Green
        
    } catch {
        Write-Host "Manual deployment also failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Go back to original directory
Set-Location ..

# Cleanup
Remove-Item $DEPLOY_DIR -Recurse -Force -ErrorAction SilentlyContinue 