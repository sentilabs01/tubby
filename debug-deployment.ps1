# 🔍 Systematic Debugging Script for Elastic Beanstalk Deployment
# This script follows the systematic debugging plan to resolve deployment issues

Write-Host "🔍 Starting Systematic Debugging Process..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Step 1: Check current environment status
Write-Host "`n📋 Step 1: Checking current environment status..." -ForegroundColor Yellow
cd backend
eb status

# Step 2: Terminate current environments if they exist
Write-Host "`n🗑️ Step 2: Terminating current environments..." -ForegroundColor Yellow
Write-Host "This will terminate any existing environments to start fresh." -ForegroundColor Red
$terminate = Read-Host "Do you want to terminate current environments? (y/n)"

if ($terminate -eq "y" -or $terminate -eq "Y") {
    Write-Host "Terminating environments..." -ForegroundColor Red
    eb terminate tubby-backend-prod --force
    eb terminate tubby-backend-prod-new --force
    Write-Host "Environments terminated. Waiting for cleanup..." -ForegroundColor Green
    Start-Sleep -Seconds 30
}

# Step 3: Create new minimal test environment
Write-Host "`n🚀 Step 3: Creating new minimal test environment..." -ForegroundColor Yellow
Write-Host "Creating environment: tubby-backend-debug" -ForegroundColor Green

# Check if we're in the backend directory
if (!(Test-Path "minimal_test.py")) {
    Write-Host "❌ Error: minimal_test.py not found in current directory" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory" -ForegroundColor Red
    exit 1
}

# Create new environment
Write-Host "Creating new environment with minimal configuration..." -ForegroundColor Green
eb create tubby-backend-debug --instance-type t2.micro --single-instance

# Step 4: Deploy minimal test app
Write-Host "`n📦 Step 4: Deploying minimal test app..." -ForegroundColor Yellow
eb deploy

# Step 5: Check deployment status
Write-Host "`n✅ Step 5: Checking deployment status..." -ForegroundColor Yellow
eb status

# Step 6: Test the deployment
Write-Host "`n🧪 Step 6: Testing the deployment..." -ForegroundColor Yellow
$envUrl = eb status | Select-String "CNAME" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
Write-Host "Environment URL: $envUrl" -ForegroundColor Green

Write-Host "`nTesting health endpoint..." -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri "http://$envUrl/health" -UseBasicParsing
    Write-Host "✅ Health check successful: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTesting root endpoint..." -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri "http://$envUrl/" -UseBasicParsing
    Write-Host "✅ Root endpoint successful: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Green
} catch {
    Write-Host "❌ Root endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 7: Show logs if there are issues
Write-Host "`n📋 Step 7: Checking logs..." -ForegroundColor Yellow
Write-Host "If deployment failed, check the logs with: eb logs --all" -ForegroundColor Cyan

Write-Host "`n🎉 Systematic debugging process completed!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. If successful, proceed to Phase 2 of the debugging plan" -ForegroundColor White
Write-Host "2. If failed, check logs and adjust the minimal app" -ForegroundColor White
Write-Host "3. Refer to SYSTEMATIC_DEBUGGING_PLAN.md for detailed next steps" -ForegroundColor White 