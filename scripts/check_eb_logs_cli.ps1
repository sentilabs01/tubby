# Check Elastic Beanstalk Logs using AWS CLI
Write-Host "Checking Elastic Beanstalk logs..." -ForegroundColor Green

$ENV_NAME = "tubby-backend-20250723-170956"

Write-Host "Environment: $ENV_NAME" -ForegroundColor Yellow

try {
    # Get recent events first
    Write-Host "Recent events:" -ForegroundColor Yellow
    aws elasticbeanstalk describe-events --environment-name $ENV_NAME --region us-east-1 --max-items 10 --query 'Events[*].[EventDate,Severity,Message]' --output table
    
    Write-Host ""
    Write-Host "Environment status:" -ForegroundColor Yellow
    $ENV_INFO = aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --region us-east-1 --query 'Environments[0]' --output json | ConvertFrom-Json
    Write-Host "Status: $($ENV_INFO.Status)" -ForegroundColor Cyan
    Write-Host "Health: $($ENV_INFO.Health)" -ForegroundColor Cyan
    Write-Host "URL: $($ENV_INFO.CNAME)" -ForegroundColor Green
    
    # Try to get logs using AWS CLI
    Write-Host ""
    Write-Host "Attempting to retrieve logs..." -ForegroundColor Yellow
    
    # Get the environment ID
    $ENV_ID = $ENV_INFO.EnvironmentId
    Write-Host "Environment ID: $ENV_ID" -ForegroundColor Cyan
    
    # Try to get logs
    try {
        aws elasticbeanstalk retrieve-environment-info --environment-name $ENV_NAME --info-type tail --region us-east-1
    } catch {
        Write-Host "Could not retrieve logs via CLI: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error checking environment: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "The 503 error suggests the Flask app isn't starting." -ForegroundColor Red
Write-Host "Possible issues:" -ForegroundColor Yellow
Write-Host "1. Flask app not starting (check logs)" -ForegroundColor Yellow
Write-Host "2. Port configuration issues" -ForegroundColor Yellow
Write-Host "3. Missing dependencies" -ForegroundColor Yellow
Write-Host "4. Procfile syntax errors" -ForegroundColor Yellow

Write-Host ""
Write-Host "To check detailed logs in AWS Console:" -ForegroundColor Green
Write-Host "1. Go to AWS Console → Elastic Beanstalk" -ForegroundColor Yellow
Write-Host "2. Click on environment: $ENV_NAME" -ForegroundColor Yellow
Write-Host "3. Click 'Logs' tab" -ForegroundColor Yellow
Write-Host "4. Click 'Request last 100 lines' or 'Request full logs'" -ForegroundColor Yellow
Write-Host "5. Look for Flask startup errors" -ForegroundColor Yellow 