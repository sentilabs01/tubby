# Quick Test Deployment Script
Write-Host "Creating ultra minimal test environment..." -ForegroundColor Green

# Set environment name
$ENV_NAME = "tubby-quick-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$DEPLOY_DIR = "deploy-quick-test"
if (Test-Path $DEPLOY_DIR) { Remove-Item $DEPLOY_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $DEPLOY_DIR | Out-Null

# Copy ultra minimal files
Copy-Item "backend/ultra_minimal_test.py" "$DEPLOY_DIR/"
Copy-Item "backend/requirements_ultra_minimal.txt" "$DEPLOY_DIR/requirements.txt"
Copy-Item "backend/Procfile_ultra_minimal" "$DEPLOY_DIR/Procfile"

# Create .ebextensions for faster deployment
New-Item -ItemType Directory -Path "$DEPLOY_DIR/.ebextensions" | Out-Null

# Minimal configuration
@"
option_settings:
  aws:elasticbeanstalk:application:environment:
    PYTHONPATH: "/var/app/current:$PYTHONPATH"
  aws:elasticbeanstalk:container:python:
    WSGIPath: ultra_minimal_test:app
"@ | Out-File -FilePath "$DEPLOY_DIR/.ebextensions/01_python.config" -Encoding UTF8

# Navigate to deploy directory
Set-Location $DEPLOY_DIR

Write-Host "Deploying to Elastic Beanstalk..." -ForegroundColor Green
try {
    # Initialize EB application
    eb init tubby-backend --platform python-3.11 --region us-east-1
    
    # Create environment with minimal settings
    eb create $ENV_NAME
    
    Write-Host "Quick test deployed successfully!" -ForegroundColor Green
    Write-Host "Environment: $ENV_NAME" -ForegroundColor Cyan
    
    # Get the URL
    $STATUS = eb status $ENV_NAME
    Write-Host "Status: $STATUS" -ForegroundColor Cyan
    
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check AWS Console for details" -ForegroundColor Yellow
}

# Go back to original directory
Set-Location ..

# Cleanup
Remove-Item $DEPLOY_DIR -Recurse -Force -ErrorAction SilentlyContinue 