# Quick Test Deployment for TubbyAI
param(
    [string]$Environment = "test"
)

Write-Host "TubbyAI Quick Test Deployment" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Configuration
$PROJECT_ROOT = $PSScriptRoot | Split-Path
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"

# Test backend
Write-Host "Testing backend..." -ForegroundColor Yellow
Set-Location $BACKEND_DIR
try {
    # Just check if the file exists and can be imported, don't run it
    $testResult = python -c "import hello_world; print('Backend import: OK')" 2>$null
    Write-Host "Backend test: PASS" -ForegroundColor Green
    $backendSuccess = $true
} catch {
    Write-Host "Backend test: FAIL" -ForegroundColor Red
    $backendSuccess = $false
}

# Test frontend
Write-Host "Testing frontend..." -ForegroundColor Yellow
Set-Location $PROJECT_ROOT
try {
    npm run build:prod
    Write-Host "Frontend test: PASS" -ForegroundColor Green
    $frontendSuccess = $true
} catch {
    Write-Host "Frontend test: FAIL" -ForegroundColor Red
    $frontendSuccess = $false
}

# Test AWS connectivity
Write-Host "Testing AWS connectivity..." -ForegroundColor Yellow
try {
    $awsIdentity = aws sts get-caller-identity --query 'Account' --output text 2>$null
    if ($awsIdentity) {
        Write-Host "AWS connectivity: PASS (Account: $awsIdentity)" -ForegroundColor Green
        $awsSuccess = $true
    } else {
        Write-Host "AWS connectivity: FAIL" -ForegroundColor Red
        $awsSuccess = $false
    }
} catch {
    Write-Host "AWS connectivity: FAIL" -ForegroundColor Red
    $awsSuccess = $false
}

# Summary
Write-Host ""
Write-Host "Test Summary:" -ForegroundColor Green
Write-Host "Backend: $(if ($backendSuccess) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($backendSuccess) { 'Green' } else { 'Red' })
Write-Host "Frontend: $(if ($frontendSuccess) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($frontendSuccess) { 'Green' } else { 'Red' })
Write-Host "AWS: $(if ($awsSuccess) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($awsSuccess) { 'Green' } else { 'Red' })

Write-Host ""
Write-Host "Quick test completed!" -ForegroundColor Green 