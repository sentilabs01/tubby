# Monitor Deployment Progress
Write-Host "Monitoring deployment progress..." -ForegroundColor Green

$ENV_NAME = "tubby-unix-20250723-173758"

Write-Host "Environment: $ENV_NAME" -ForegroundColor Yellow

$maxAttempts = 30
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "Check $attempt of $maxAttempts..." -ForegroundColor Yellow
    
    try {
        # Get environment details
        $ENV_INFO = aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --region us-east-1 --query 'Environments[0]' --output json | ConvertFrom-Json
        
        Write-Host "Status: $($ENV_INFO.Status)" -ForegroundColor Cyan
        Write-Host "Health: $($ENV_INFO.Health)" -ForegroundColor Cyan
        Write-Host "URL: $($ENV_INFO.CNAME)" -ForegroundColor Green
        
        # Check if environment is ready
        if ($ENV_INFO.Status -eq "Ready" -and $ENV_INFO.Health -eq "Green") {
            Write-Host ""
            Write-Host "🎉 SUCCESS! Environment is ready!" -ForegroundColor Green
            Write-Host "Test URL: http://$($ENV_INFO.CNAME)" -ForegroundColor Green
            Write-Host "Health endpoint: http://$($ENV_INFO.CNAME)/health" -ForegroundColor Green
            break
        } elseif ($ENV_INFO.Status -eq "Ready" -and $ENV_INFO.Health -eq "Grey") {
            Write-Host ""
            Write-Host "⚠️ Environment is Ready but Health is Grey!" -ForegroundColor Red
            Write-Host "This means the infrastructure is ready but the Flask app isn't starting." -ForegroundColor Red
            Write-Host "Check AWS Console logs for Flask startup errors." -ForegroundColor Red
            break
        } elseif ($ENV_INFO.Status -eq "Terminated") {
            Write-Host ""
            Write-Host "❌ Environment was terminated. Check AWS Console for details." -ForegroundColor Red
            break
        } else {
            Write-Host "⏳ Environment is still launching... waiting 30 seconds" -ForegroundColor Yellow
            Start-Sleep -Seconds 30
        }
        
    } catch {
        Write-Host "Error checking environment: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 30
    }
}

if ($attempt -eq $maxAttempts) {
    Write-Host "⏰ Monitoring timeout. Check AWS Console for final status." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 To check logs in AWS Console:" -ForegroundColor Green
Write-Host "1. Go to AWS Console → Elastic Beanstalk" -ForegroundColor Yellow
Write-Host "2. Click on environment: $ENV_NAME" -ForegroundColor Yellow
Write-Host "3. Click 'Logs' tab" -ForegroundColor Yellow
Write-Host "4. Click 'Request last 100 lines' or 'Request full logs'" -ForegroundColor Yellow 