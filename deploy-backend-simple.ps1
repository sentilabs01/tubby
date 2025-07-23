# Simple Backend Deployment Script for Elastic Beanstalk
param(
    [string]$EnvironmentName = "tubby-backend-prod"
)

Write-Host "Deploying Backend to Elastic Beanstalk" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "backend")) {
    Write-Host "Error: backend directory not found" -ForegroundColor Red
    Write-Host "Please run this script from the project root" -ForegroundColor Yellow
    exit 1
}

# Change to backend directory
Push-Location backend

# Check if requirements.txt exists
if (-not (Test-Path "requirements.txt")) {
    Write-Host "Creating requirements.txt..." -ForegroundColor Yellow
    if (Test-Path "requirements_production.txt") {
        Copy-Item "requirements_production.txt" "requirements.txt"
    } else {
        Write-Host "Error: requirements_production.txt not found" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Create Procfile for EB
Write-Host "Creating Procfile..." -ForegroundColor Yellow
$procfile = "web: gunicorn --config gunicorn.conf.py app:app"
$procfile | Out-File -FilePath "Procfile" -Encoding UTF8

# Create .ebextensions directory
if (-not (Test-Path ".ebextensions")) {
    New-Item -ItemType Directory -Path ".ebextensions" | Out-Null
}

# Create environment variables configuration
$envVarsConfig = @"
option_settings:
  aws:elasticbeanstalk:application:environment:
    FLASK_ENV: production
    PORT: 5004
    HOST: 0.0.0.0
    # Add your environment variables here
    # SUPABASE_URL: your-supabase-url
    # SUPABASE_ANON_KEY: your-supabase-anon-key
    # STRIPE_SECRET_KEY: your-stripe-secret-key
    # etc.
"@

$envVarsConfig | Out-File -FilePath ".ebextensions\env.config" -Encoding UTF8

# Check if environment exists
Write-Host "Checking environment status..." -ForegroundColor Yellow
$envStatus = eb status $EnvironmentName 2>$null
if (-not $envStatus) {
    Write-Host "Environment '$EnvironmentName' does not exist" -ForegroundColor Red
    Write-Host "Creating new environment..." -ForegroundColor Yellow
    
    # Create environment
    eb create $EnvironmentName --timeout 20 --elb-type application
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create environment" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Deploy to EB
Write-Host "Deploying to Elastic Beanstalk..." -ForegroundColor Yellow
try {
    eb deploy $EnvironmentName --timeout 20
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment successful!" -ForegroundColor Green
        
        # Get environment URL
        $envUrl = eb status $EnvironmentName --output json 2>$null | ConvertFrom-Json | Select-Object -ExpandProperty CNAME
        if ($envUrl) {
            Write-Host "Backend URL: http://$envUrl" -ForegroundColor Green
            Write-Host "Health Check: http://$envUrl/health" -ForegroundColor Green
        }
    } else {
        Write-Host "Deployment failed" -ForegroundColor Red
        Pop-Location
        exit 1
    }
} catch {
    Write-Host "Deployment error: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Return to original directory
Pop-Location

Write-Host "`nBackend deployment completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure environment variables in EB Console" -ForegroundColor White
Write-Host "2. Set up your domain (if you have one)" -ForegroundColor White
Write-Host "3. Configure CORS settings for your frontend domain" -ForegroundColor White
Write-Host "4. Test the backend API endpoints" -ForegroundColor White
Write-Host "5. Deploy frontend to Amplify" -ForegroundColor White

Write-Host "`nEnvironment Variables to configure:" -ForegroundColor Cyan
Write-Host "- SUPABASE_URL" -ForegroundColor White
Write-Host "- SUPABASE_ANON_KEY" -ForegroundColor White
Write-Host "- SUPABASE_SERVICE_ROLE_KEY" -ForegroundColor White
Write-Host "- GOOGLE_CLIENT_ID" -ForegroundColor White
Write-Host "- GOOGLE_CLIENT_SECRET" -ForegroundColor White
Write-Host "- GITHUB_CLIENT_ID" -ForegroundColor White
Write-Host "- GITHUB_CLIENT_SECRET" -ForegroundColor White
Write-Host "- STRIPE_SECRET_KEY" -ForegroundColor White
Write-Host "- STRIPE_PUBLISHABLE_KEY" -ForegroundColor White
Write-Host "- SECRET_KEY" -ForegroundColor White
Write-Host "- FRONTEND_URL" -ForegroundColor White
Write-Host "- BACKEND_URL" -ForegroundColor White 