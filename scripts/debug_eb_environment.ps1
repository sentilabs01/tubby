# Debug Elastic Beanstalk Environment
Write-Host "Debugging Elastic Beanstalk environment..." -ForegroundColor Green

$ENV_NAME = "tubbyai-env-1"

Write-Host "Environment: $ENV_NAME" -ForegroundColor Yellow

try {
    # Check environment status
    Write-Host "Checking environment status..." -ForegroundColor Yellow
    $ENV_INFO = aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --query 'Environments[0]' --output json | ConvertFrom-Json
    
    Write-Host "Status: $($ENV_INFO.Status)" -ForegroundColor Cyan
    Write-Host "Health: $($ENV_INFO.Health)" -ForegroundColor Cyan
    Write-Host "URL: $($ENV_INFO.CNAME)" -ForegroundColor Cyan
    
    # Get recent events
    Write-Host ""
    Write-Host "Recent events:" -ForegroundColor Yellow
    aws elasticbeanstalk describe-events --environment-name $ENV_NAME --max-items 5 --query 'Events[*].[EventDate,Severity,Message]' --output table
    
} catch {
    Write-Host "Error checking environment: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "To check detailed logs in AWS Console:" -ForegroundColor Green
Write-Host "1. Go to AWS Console → Elastic Beanstalk" -ForegroundColor Yellow
Write-Host "2. Click on environment: $ENV_NAME" -ForegroundColor Yellow
Write-Host "3. Click 'Logs' tab" -ForegroundColor Yellow
Write-Host "4. Click 'Request last 100 lines' or 'Request full logs'" -ForegroundColor Yellow
Write-Host "5. Look for error messages about Flask app startup" -ForegroundColor Yellow

Write-Host ""
Write-Host "Common 502 error causes:" -ForegroundColor Green
Write-Host "- Flask app not starting (check logs)" -ForegroundColor Yellow
Write-Host "- Port configuration issues" -ForegroundColor Yellow
Write-Host "- Missing dependencies" -ForegroundColor Yellow
Write-Host "- Procfile syntax errors" -ForegroundColor Yellow 