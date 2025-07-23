# AWS Elastic Beanstalk Backend Deployment Script
# This script deploys the Tubby AI backend to AWS Elastic Beanstalk

param(
    [string]$EnvironmentName = "tubby-backend-prod",
    [string]$ApplicationName = "tubby-ai",
    [string]$Region = "us-east-1",
    [switch]$CreateEnvironment,
    [switch]$UpdateEnvironment
)

Write-Host "🚀 Tubby AI Backend Deployment to Elastic Beanstalk" -ForegroundColor Blue

# Check if EB CLI is installed
if (-not (Get-Command eb -ErrorAction SilentlyContinue)) {
    Write-Host "❌ EB CLI not found. Installing..." -ForegroundColor Yellow
    pip install awsebcli
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install EB CLI" -ForegroundColor Red
        exit 1
    }
}

# Check AWS credentials
Write-Host "🔑 Checking AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
    if ($identity) {
        Write-Host "✅ AWS credentials found for: $($identity.Arn)" -ForegroundColor Green
    } else {
        Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
        Write-Host "Run: aws configure" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
    Write-Host "Run: aws configure" -ForegroundColor Yellow
    exit 1
}

# Navigate to backend directory
Push-Location backend

# Check if EB project is initialized
if (-not (Test-Path ".elasticbeanstalk\config.yml")) {
    Write-Host "🔧 Initializing EB project..." -ForegroundColor Yellow
    
    # Create .ebignore file
    $ebIgnore = @"
# Ignore files not needed for deployment
venv/
__pycache__/
*.pyc
.env.local
.env.development
*.log
.DS_Store
"@
    $ebIgnore | Out-File -FilePath ".ebignore" -Encoding UTF8
    
    # Initialize EB project
    eb init $ApplicationName --region $Region --platform "Python 3.9" --timeout 20
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to initialize EB project" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Create environment if requested
if ($CreateEnvironment) {
    Write-Host "🌍 Creating EB environment: $EnvironmentName" -ForegroundColor Yellow
    
    # Create environment configuration
    $envConfig = @"
option_settings:
  aws:elasticbeanstalk:application:environment:
    FLASK_ENV: production
    PORT: 5004
    HOST: 0.0.0.0
  aws:elasticbeanstalk:container:python:
    WSGIPath: app:app
  aws:elasticbeanstalk:environment:proxy:staticfiles:
    /static: static
  aws:autoscaling:launchconfiguration:
    InstanceType: t3.small
    IamInstanceProfile: aws-elasticbeanstalk-ec2-role
  aws:autoscaling:asg:
    MinSize: 1
    MaxSize: 4
  aws:elasticbeanstalk:healthreporting:system:
    SystemType: enhanced
"@
    
    $envConfig | Out-File -FilePath ".ebextensions\environment.config" -Encoding UTF8
    
    # Create environment
    eb create $EnvironmentName --timeout 20 --elb-type application
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create environment" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Check if environment exists
Write-Host "🔍 Checking environment status..." -ForegroundColor Yellow
$envStatus = eb status $EnvironmentName 2>$null
if (-not $envStatus) {
    Write-Host "❌ Environment '$EnvironmentName' does not exist" -ForegroundColor Red
    Write-Host "Use -CreateEnvironment flag to create it" -ForegroundColor Yellow
    Pop-Location
    exit 1
}

# Create requirements.txt if it doesn't exist
if (-not (Test-Path "requirements.txt")) {
    Write-Host "📝 Creating requirements.txt..." -ForegroundColor Yellow
    Copy-Item "requirements_production.txt" "requirements.txt"
}

# Create Procfile for EB
Write-Host "📝 Creating Procfile..." -ForegroundColor Yellow
$procfile = "web: gunicorn --config gunicorn.conf.py app:app"
$procfile | Out-File -FilePath "Procfile" -Encoding UTF8

# Create .ebextensions for environment variables
Write-Host "⚙️ Setting up environment configuration..." -ForegroundColor Yellow
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

# Deploy to EB
Write-Host "🚀 Deploying to Elastic Beanstalk..." -ForegroundColor Yellow
try {
    eb deploy $EnvironmentName --timeout 20
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
        
        # Get environment URL
        $envUrl = eb status $EnvironmentName --output json 2>$null | ConvertFrom-Json | Select-Object -ExpandProperty CNAME
        if ($envUrl) {
            Write-Host "🌐 Backend URL: http://$envUrl" -ForegroundColor Green
            Write-Host "🔗 Health Check: http://$envUrl/health" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ Deployment failed" -ForegroundColor Red
        Pop-Location
        exit 1
    }
} catch {
    Write-Host "❌ Deployment error: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Return to original directory
Pop-Location

Write-Host "`n🎉 Backend deployment completed!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure environment variables in EB Console" -ForegroundColor White
Write-Host "2. Set up your domain (if you have one)" -ForegroundColor White
Write-Host "3. Configure CORS settings for your frontend domain" -ForegroundColor White
Write-Host "4. Test the backend API endpoints" -ForegroundColor White
Write-Host "5. Deploy frontend to Amplify" -ForegroundColor White

Write-Host "`n🔧 Environment Variables to configure:" -ForegroundColor Cyan
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