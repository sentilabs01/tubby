# Fix EB Port Issue
param(
    [string]$Environment = "Tubbyai-env"
)

Write-Host "Fixing EB Port Configuration" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Configuration
$PROJECT_ROOT = $PSScriptRoot | Split-Path
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"

# Create deployment package
Write-Host "Creating fixed deployment package..." -ForegroundColor Yellow

$TEMP_DIR = Join-Path $PROJECT_ROOT "fix-eb-$TIMESTAMP"
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

# Copy application files
Write-Host "  Copying application files..." -ForegroundColor Cyan
Copy-Item "$BACKEND_DIR\application.py" $TEMP_DIR

# Create requirements.txt
$REQUIREMENTS = @"
flask==2.3.3
gunicorn==21.2.0
"@
$REQUIREMENTS | Out-File -FilePath (Join-Path $TEMP_DIR "requirements.txt") -Encoding UTF8

# Create .ebextensions to fix port configuration
$EBEXTENSIONS_DIR = Join-Path $TEMP_DIR ".ebextensions"
New-Item -ItemType Directory -Path $EBEXTENSIONS_DIR -Force | Out-Null

# Create configuration to use port 8000 (EB default)
$EB_CONFIG = @"
option_settings:
  aws:elasticbeanstalk:container:python:
    WSGIPath: application:app
  aws:elasticbeanstalk:application:environment:
    PORT: 8000
  aws:elasticbeanstalk:environment:proxy:
    ProxyServer: nginx
"@

$EB_CONFIG | Out-File -FilePath (Join-Path $EBEXTENSIONS_DIR "01_config.config") -Encoding UTF8

# Create application.py that uses port 8000
$APP_CONTENT = @"
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello World from TubbyAI!'

@app.route('/health')
def health():
    return 'OK'

@app.route('/test')
def test():
    return 'Test endpoint working!'

if __name__ == '__main__':
    # Use port 8000 for EB compatibility
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port)
"@

$APP_CONTENT | Out-File -FilePath (Join-Path $TEMP_DIR "application.py") -Encoding UTF8

# Create Procfile
$PROCFILE = "web: gunicorn --bind 0.0.0.0:8000 --workers 1 --timeout 120 application:app"
$PROCFILE | Out-File -FilePath (Join-Path $TEMP_DIR "Procfile") -Encoding UTF8

# Create ZIP package
Write-Host "  Creating deployment package..." -ForegroundColor Cyan
$ZIP_FILE = Join-Path $PROJECT_ROOT "fix-eb-$TIMESTAMP.zip"
Compress-Archive -Path "$TEMP_DIR\*" -DestinationPath $ZIP_FILE -Force

# Deploy to EB
Write-Host "Deploying to EB..." -ForegroundColor Yellow

try {
    $ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
    $BUCKET = "elasticbeanstalk-us-east-1-$ACCOUNT_ID"
    $ZIP_FILE_NAME = "fix-eb-$TIMESTAMP.zip"
    
    Write-Host "  Account ID: $ACCOUNT_ID" -ForegroundColor Cyan
    Write-Host "  S3 Bucket: $BUCKET" -ForegroundColor Cyan
    
    # Upload to S3
    Write-Host "  Uploading to S3..." -ForegroundColor Cyan
    aws s3 cp $ZIP_FILE_NAME "s3://$BUCKET/$ZIP_FILE_NAME" --region us-east-1
    
    # Create application version
    Write-Host "  Creating application version..." -ForegroundColor Cyan
    $VERSION_LABEL = "fix-port-v-$TIMESTAMP"
    aws elasticbeanstalk create-application-version --application-name tubbyai --version-label $VERSION_LABEL --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE_NAME --region us-east-1
    
    # Update environment
    Write-Host "  Updating environment: $Environment" -ForegroundColor Cyan
    aws elasticbeanstalk update-environment --environment-name $Environment --version-label $VERSION_LABEL --region us-east-1
    
    Write-Host "  Deployment initiated!" -ForegroundColor Green
    Write-Host "  Environment: $Environment" -ForegroundColor Cyan
    Write-Host "  Version: $VERSION_LABEL" -ForegroundColor Cyan
    
    # Wait for deployment
    Write-Host "  Waiting for deployment to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
    
    # Get environment info
    $envInfo = aws elasticbeanstalk describe-environments --environment-names $Environment --region us-east-1 --query 'Environments[0]' --output json | ConvertFrom-Json
    
    Write-Host "  Status: $($envInfo.Status)" -ForegroundColor Cyan
    Write-Host "  Health: $($envInfo.Health)" -ForegroundColor Cyan
    if ($envInfo.CNAME) {
        Write-Host "  URL: http://$($envInfo.CNAME)" -ForegroundColor Green
    }
    
    # Test the application
    if ($envInfo.Status -eq "Ready") {
        Write-Host "  Testing application..." -ForegroundColor Cyan
        Start-Sleep -Seconds 30
        
        try {
            $response = Invoke-WebRequest -Uri "http://$($envInfo.CNAME)/health" -TimeoutSec 10 -UseBasicParsing
            Write-Host "  ✅ Application is responding!" -ForegroundColor Green
            Write-Host "  Response: $($response.Content.Trim())" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Application not responding yet: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup
    Remove-Item $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ZIP_FILE -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Port fix deployment complete!" -ForegroundColor Green 