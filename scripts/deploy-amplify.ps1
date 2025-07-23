# Amplify Deployment Script for Tubby AI (PowerShell)
# This script helps prepare and deploy the application to AWS Amplify

param(
    [switch]$SkipTests
)

Write-Host "🚀 Starting Tubby AI Amplify Deployment..." -ForegroundColor Green

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if we're in the right directory
if (-not (Test-Path "package.json") -or -not (Test-Path "amplify.yml")) {
    Write-Error "This script must be run from the project root directory"
    exit 1
}

# Step 1: Check environment variables
Write-Status "Checking environment variables..."
if (-not (Test-Path ".env")) {
    Write-Warning "No .env file found. Please create one from env.example"
    Write-Status "Copying env.example to .env..."
    Copy-Item "env.example" ".env"
    Write-Warning "Please edit .env with your actual values before deploying"
}

# Step 2: Install dependencies
Write-Status "Installing frontend dependencies..."
npm ci

Write-Status "Installing backend dependencies..."
Set-Location backend
pip install -r requirements_production.txt
Set-Location ..

# Step 3: Build frontend
Write-Status "Building frontend application..."
npm run build

# Step 4: Test backend (if not skipped)
if (-not $SkipTests) {
    Write-Status "Testing backend health..."
    Set-Location backend
    python -c "
import os
import sys
sys.path.append('.')
from app_production import app
with app.test_client() as client:
    response = client.get('/health')
    if response.status_code == 200:
        print('✅ Backend health check passed')
    else:
        print('❌ Backend health check failed')
        sys.exit(1)
"
    Set-Location ..
}

# Step 5: Check for required files
Write-Status "Checking required files for deployment..."

$requiredFiles = @(
    "amplify.yml",
    "package.json",
    "vite.config.js",
    "backend/requirements_production.txt",
    "backend/start_production.py",
    "backend/app_production.py",
    "dist/index.html"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Status "✅ $file found"
    } else {
        Write-Error "❌ $file not found"
        exit 1
    }
}

# Step 6: Git status check
Write-Status "Checking Git status..."
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Warning "You have uncommitted changes. Consider committing them before deployment."
    git status --short
} else {
    Write-Status "✅ Working directory is clean"
}

# Step 7: Deployment instructions
Write-Host ""
Write-Status "🎉 Preparation complete! Ready for Amplify deployment."
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Push your changes to GitHub:"
Write-Host "   git add ."
Write-Host "   git commit -m 'Prepare for Amplify deployment'"
Write-Host "   git push origin main"
Write-Host ""
Write-Host "2. In AWS Amplify Console:"
Write-Host "   - Connect your GitHub repository"
Write-Host "   - Configure environment variables"
Write-Host "   - Deploy the application"
Write-Host ""
Write-Host "3. Set up external services:"
Write-Host "   - Redis instance (ElastiCache recommended)"
Write-Host "   - Supabase production database"
Write-Host "   - OAuth redirect URLs"
Write-Host ""
Write-Host "For detailed instructions, see: AMPLIFY_DEPLOYMENT_GUIDE.md"

Write-Status "Deployment preparation completed successfully! 🚀" 