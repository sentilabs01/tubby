# Test All EB Environments
Write-Host "Testing All EB Environments" -ForegroundColor Green
Write-Host "==========================" -ForegroundColor Green

# Get all environments
$environments = aws elasticbeanstalk describe-environments --application-name tubbyai --region us-east-1 --query 'Environments[]' --output json | ConvertFrom-Json

Write-Host "Found $($environments.Count) environments:" -ForegroundColor Cyan

foreach ($env in $environments) {
    Write-Host ""
    Write-Host "Testing: $($env.EnvironmentName)" -ForegroundColor Yellow
    Write-Host "  Status: $($env.Status)" -ForegroundColor Cyan
    Write-Host "  Health: $($env.Health)" -ForegroundColor Cyan
    Write-Host "  URL: $($env.CNAME)" -ForegroundColor Cyan
    
    if ($env.Status -eq "Ready") {
        # Test the environment
        try {
            $response = Invoke-WebRequest -Uri "http://$($env.CNAME)/health" -TimeoutSec 10 -UseBasicParsing
            Write-Host "  ✅ Health endpoint: $($response.StatusCode) - $($response.Content.Trim())" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Health endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        try {
            $response = Invoke-WebRequest -Uri "http://$($env.CNAME)/" -TimeoutSec 10 -UseBasicParsing
            Write-Host "  ✅ Root endpoint: $($response.StatusCode) - $($response.Content.Trim())" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Root endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠️ Environment not ready" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Green
Write-Host "========" -ForegroundColor Green
$working = $environments | Where-Object { $_.Status -eq "Ready" -and $_.Health -eq "Green" }
Write-Host "Working environments: $($working.Count)" -ForegroundColor Cyan
$ready = $environments | Where-Object { $_.Status -eq "Ready" }
Write-Host "Ready environments: $($ready.Count)" -ForegroundColor Cyan 