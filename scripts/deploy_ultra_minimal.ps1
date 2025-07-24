# Ultra Minimal Test Deployment Script
Write-Host "Deploying Ultra Minimal Test to Elastic Beanstalk..." -ForegroundColor Green

# Set environment name
$ENV_NAME = "tubby-ultra-minimal-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$DEPLOY_DIR = "deploy-ultra-minimal"
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
  aws:elasticbeanstalk:environment:proxy:staticfiles:
    /static: static
"@ | Out-File -FilePath "$DEPLOY_DIR/.ebextensions/01_python.config" -Encoding UTF8

# Deploy to Elastic Beanstalk
Write-Host "Deploying to Elastic Beanstalk..." -ForegroundColor Green
try {
    # Initialize EB application if needed
    eb init tubby-backend --platform python-3.11 --region us-east-1 --force
    
    # Create environment
    eb create $ENV_NAME --instance-type t2.micro --single-instance --timeout 10
    
    Write-Host "Ultra minimal test deployed successfully!" -ForegroundColor Green
    Write-Host "Environment: $ENV_NAME" -ForegroundColor Cyan
    
    # Get the URL
    $URL = eb status $ENV_NAME --output json | ConvertFrom-Json | Select-Object -ExpandProperty CNAME
    Write-Host "URL: http://$URL" -ForegroundColor Cyan
    
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check AWS Console for details" -ForegroundColor Yellow
}

# Cleanup
Remove-Item $DEPLOY_DIR -Recurse -Force -ErrorAction SilentlyContinue 