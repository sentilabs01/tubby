# Check Environment Status Script
Write-Host "Checking environment status..." -ForegroundColor Green

# Get environment status using AWS CLI
$ENV_NAME = "tubby-quick-test-20250723-160841"

try {
    $ENV_INFO = aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --query 'Environments[0]' --output json | ConvertFrom-Json
    
    Write-Host "Environment: $($ENV_INFO.EnvironmentName)" -ForegroundColor Cyan
    Write-Host "Status: $($ENV_INFO.Status)" -ForegroundColor Yellow
    Write-Host "Health: $($ENV_INFO.Health)" -ForegroundColor Yellow
    Write-Host "URL: $($ENV_INFO.CNAME)" -ForegroundColor Green
    
    if ($ENV_INFO.Status -eq "Ready" -and $ENV_INFO.Health -eq "Green") {
        Write-Host "Environment is ready!" -ForegroundColor Green
        Write-Host "Test URL: http://$($ENV_INFO.CNAME)" -ForegroundColor Green
    } else {
        Write-Host "Environment is still starting up..." -ForegroundColor Yellow
        Write-Host "Check AWS Console for more details" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error checking environment: $($_.Exception.Message)" -ForegroundColor Red
} 