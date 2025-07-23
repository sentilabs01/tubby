# Deploy using Git method (bypasses ZIP issues)
Write-Host "Deploying using Git method..." -ForegroundColor Green

# Check if eb CLI is installed
try {
    eb --version | Out-Null
    Write-Host "EB CLI found!" -ForegroundColor Green
} catch {
    Write-Host "EB CLI not found. Installing..." -ForegroundColor Yellow
    pip install awsebcli
}

# Initialize EB project
Write-Host "Initializing EB project..." -ForegroundColor Yellow
eb init tubbyai --platform python-3.11 --region us-east-1

# Create environment
Write-Host "Creating environment..." -ForegroundColor Yellow
$ENV_NAME = "tubby-git-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
eb create $ENV_NAME --single-instance --elb-type application

Write-Host "Git-based deployment initiated!" -ForegroundColor Green
Write-Host "Environment: $ENV_NAME" -ForegroundColor Cyan

Write-Host ""
Write-Host "This method uses Git to deploy, bypassing ZIP file issues." -ForegroundColor Green 