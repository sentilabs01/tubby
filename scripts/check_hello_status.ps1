# Check Hello World Environment Status
Write-Host "Checking Hello World environment status..." -ForegroundColor Green

$ENV_NAME = "tubby-hello-20250723-173020"

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
    } elseif ($ENV_INFO.Status -eq "Ready" -and $ENV_INFO.Health -eq "Grey") {
        Write-Host ""
        Write-Host "⚠️ Environment is Ready but Health is Grey!" -ForegroundColor Red
        Write-Host "This means the infrastructure is ready but the Flask app isn't starting." -ForegroundColor Red
        Write-Host "The 503 error confirms this." -ForegroundColor Red
    } elseif ($ENV_INFO.Status -eq "Launching") {
        Write-Host ""
        Write-Host "Environment is still launching..." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error checking environment: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔍 CRITICAL: We need to check the AWS Console logs!" -ForegroundColor Red
Write-Host "The 503 error means the Flask app isn't starting." -ForegroundColor Red
Write-Host "Possible causes:" -ForegroundColor Yellow
Write-Host "1. Flask app not starting (check logs)" -ForegroundColor Yellow
Write-Host "2. Port configuration issues" -ForegroundColor Yellow
Write-Host "3. Missing dependencies" -ForegroundColor Yellow
Write-Host "4. Procfile syntax errors" -ForegroundColor Yellow
Write-Host "5. Python version mismatch" -ForegroundColor Yellow

Write-Host ""
Write-Host "📋 To check logs in AWS Console:" -ForegroundColor Green
Write-Host "1. Go to AWS Console → Elastic Beanstalk" -ForegroundColor Yellow
Write-Host "2. Click on environment: $ENV_NAME" -ForegroundColor Yellow
Write-Host "3. Click 'Logs' tab" -ForegroundColor Yellow
Write-Host "4. Click 'Request last 100 lines' or 'Request full logs'" -ForegroundColor Yellow
Write-Host "5. Look for Flask startup errors or Python errors" -ForegroundColor Yellow 