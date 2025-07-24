# Simple Test Script - Won't hang
Write-Host "TubbyAI Simple Test" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green

# Test 1: Check Python
Write-Host "Testing Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Python: FAIL" -ForegroundColor Red
}

# Test 2: Check Node.js
Write-Host "Testing Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    Write-Host "Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Node.js: FAIL" -ForegroundColor Red
}

# Test 3: Check AWS CLI
Write-Host "Testing AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version 2>&1
    Write-Host "AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "AWS CLI: FAIL" -ForegroundColor Red
}

# Test 4: Check Docker
Write-Host "Testing Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>&1
    Write-Host "Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "Docker: FAIL" -ForegroundColor Red
}

# Test 5: Check backend file exists
Write-Host "Testing backend files..." -ForegroundColor Yellow
if (Test-Path "backend\hello_world.py") {
    Write-Host "Backend files: OK" -ForegroundColor Green
} else {
    Write-Host "Backend files: MISSING" -ForegroundColor Red
}

# Test 6: Check package.json
Write-Host "Testing frontend files..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    Write-Host "Frontend files: OK" -ForegroundColor Green
} else {
    Write-Host "Frontend files: MISSING" -ForegroundColor Red
}

Write-Host ""
Write-Host "Simple test completed!" -ForegroundColor Green 