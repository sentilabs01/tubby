# Check Elastic Beanstalk Logs
Write-Host "Checking Elastic Beanstalk logs..." -ForegroundColor Green

$ENV_NAME = "Tubbyai-env"

try {
    # Get recent events
    Write-Host "Recent events:" -ForegroundColor Yellow
    aws elasticbeanstalk describe-events --environment-name $ENV_NAME --max-items 10 --query 'Events[*].[EventDate,Severity,Message]' --output table
    
    Write-Host ""
    Write-Host "Environment health:" -ForegroundColor Yellow
    aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --query 'Environments[0].[Status,Health]' --output table
    
} catch {
    Write-Host "Error checking logs: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try checking logs in AWS Console instead" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "To check logs in AWS Console:" -ForegroundColor Green
Write-Host "1. Go to Elastic Beanstalk Console" -ForegroundColor Yellow
Write-Host "2. Click on environment: $ENV_NAME" -ForegroundColor Yellow
Write-Host "3. Click 'Logs' tab" -ForegroundColor Yellow
Write-Host "4. Click 'Request last 100 lines' or 'Request full logs'" -ForegroundColor Yellow 