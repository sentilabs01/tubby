# Monitor Elastic Beanstalk Environment
Write-Host "Monitoring Elastic Beanstalk environment..." -ForegroundColor Green

$ENV_NAME = "tubby-backend-20250723-170811"

Write-Host "Environment: $ENV_NAME" -ForegroundColor Yellow

try {
    # Get environment details
    Write-Host "Getting environment details..." -ForegroundColor Yellow
    $ENV_INFO = aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --region us-east-1 --query 'Environments[0]' --output json | ConvertFrom-Json
    
    Write-Host "Status: $($ENV_INFO.Status)" -ForegroundColor Cyan
    Write-Host "Health: $($ENV_INFO.Health)" -ForegroundColor Cyan
    Write-Host "URL: $($ENV_INFO.CNAME)" -ForegroundColor Green
    
    # Get recent events
    Write-Host ""
    Write-Host "Recent events:" -ForegroundColor Yellow
    aws elasticbeanstalk describe-events --environment-name $ENV_NAME --region us-east-1 --max-items 10 --query 'Events[*].[EventDate,Severity,Message]' --output table
    
    # Check if environment is ready
    if ($ENV_INFO.Status -eq "Ready" -and $ENV_INFO.Health -eq "Green") {
        Write-Host ""
        Write-Host "Environment is ready!" -ForegroundColor Green
        Write-Host "Test URL: http://$($ENV_INFO.CNAME)" -ForegroundColor Green
        Write-Host "Health endpoint: http://$($ENV_INFO.CNAME)/health" -ForegroundColor Green
    } elseif ($ENV_INFO.Status -eq "Launching") {
        Write-Host ""
        Write-Host "Environment is still launching..." -ForegroundColor Yellow
        Write-Host "This may take 5-10 minutes." -ForegroundColor Yellow
    } elseif ($ENV_INFO.Status -eq "Terminated") {
        Write-Host ""
        Write-Host "Environment was terminated. Check events above for reason." -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error monitoring environment: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "To check logs in AWS Console:" -ForegroundColor Green
Write-Host "1. Go to AWS Console → Elastic Beanstalk" -ForegroundColor Yellow
Write-Host "2. Click on environment: $ENV_NAME" -ForegroundColor Yellow
Write-Host "3. Click 'Logs' tab" -ForegroundColor Yellow
Write-Host "4. Click 'Request last 100 lines' or 'Request full logs'" -ForegroundColor Yellow 