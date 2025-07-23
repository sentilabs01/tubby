# Complete AWS Deployment Script for Tubby AI
# This script handles both backend (EB) and frontend (Amplify) deployment

param(
    [string]$EnvironmentName = "tubby-backend-prod",
    [string]$ApplicationName = "tubby-ai",
    [string]$Region = "us-east-1",
    [switch]$CreateEnvironment,
    [switch]$SetupAmplify,
    [switch]$SkipBackend
)

Write-Host "🚀 Tubby AI Complete AWS Deployment" -ForegroundColor Blue
Write-Host "=====================================" -ForegroundColor Blue

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

# Step 1: Deploy Backend (if not skipped)
if (-not $SkipBackend) {
    Write-Host "`n📋 Step 1: Deploying Backend to Elastic Beanstalk" -ForegroundColor Cyan
    
    # Check if EB CLI is installed
    if (-not (Get-Command eb -ErrorAction SilentlyContinue)) {
        Write-Host "📦 Installing EB CLI..." -ForegroundColor Yellow
        pip install awsebcli
    }
    
    # Deploy backend
    if ($CreateEnvironment) {
        Write-Host "🌍 Creating new EB environment..." -ForegroundColor Yellow
        .\deploy-backend-eb.ps1 -CreateEnvironment -EnvironmentName $EnvironmentName -ApplicationName $ApplicationName
    } else {
        Write-Host "🔄 Updating existing EB environment..." -ForegroundColor Yellow
        .\deploy-backend-eb.ps1 -EnvironmentName $EnvironmentName -ApplicationName $ApplicationName
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Backend deployment failed" -ForegroundColor Red
        exit 1
    }
    
    # Get backend URL
    Write-Host "🔍 Getting backend URL..." -ForegroundColor Yellow
    Push-Location backend
    $backendUrl = eb status $EnvironmentName --output json 2>$null | ConvertFrom-Json | Select-Object -ExpandProperty CNAME
    Pop-Location
    
    if ($backendUrl) {
        $backendUrl = "https://$backendUrl"
        Write-Host "✅ Backend URL: $backendUrl" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Could not get backend URL automatically" -ForegroundColor Yellow
        $backendUrl = "https://your-eb-environment.elasticbeanstalk.com"
    }
} else {
    Write-Host "⏭️ Skipping backend deployment" -ForegroundColor Yellow
    $backendUrl = "https://your-eb-environment.elasticbeanstalk.com"
}

# Step 2: Setup Frontend for Amplify
Write-Host "`n📋 Step 2: Setting up Frontend for Amplify" -ForegroundColor Cyan

# Build frontend
Write-Host "🔨 Building frontend..." -ForegroundColor Yellow
npm run build:prod
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Frontend build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Frontend build successful" -ForegroundColor Green

# Create .env.production template
Write-Host "📝 Creating environment variables template..." -ForegroundColor Yellow
$envTemplate = @"
# Backend API URL (update with your actual backend URL)
VITE_API_URL=$backendUrl

# Supabase Configuration
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key

# OAuth Configuration
VITE_GOOGLE_CLIENT_ID=your-google-client-id
VITE_GITHUB_CLIENT_ID=your-github-client-id

# Stripe Configuration
VITE_STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
"@

$envTemplate | Out-File -FilePath ".env.production.template" -Encoding UTF8
Write-Host "✅ Created .env.production.template" -ForegroundColor Green

# Check git status
Write-Host "🔍 Checking git status..." -ForegroundColor Yellow
$gitStatus = git status --porcelain 2>$null
if ($gitStatus) {
    Write-Host "📝 Changes detected in git repository" -ForegroundColor Yellow
    Write-Host "💡 Consider committing changes before pushing to GitHub" -ForegroundColor Cyan
} else {
    Write-Host "✅ No uncommitted changes" -ForegroundColor Green
}

# Step 3: Amplify Setup Instructions
Write-Host "`n📋 Step 3: Amplify Setup Instructions" -ForegroundColor Cyan

Write-Host "`n🔧 To complete the deployment:" -ForegroundColor Yellow
Write-Host "1. Push your code to GitHub:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'Ready for Amplify deployment'" -ForegroundColor Gray
Write-Host "   git push origin main" -ForegroundColor Gray

Write-Host "`n2. Set up AWS Amplify:" -ForegroundColor White
Write-Host "   - Go to AWS Amplify Console" -ForegroundColor Gray
Write-Host "   - Click 'New app' → 'Host web app'" -ForegroundColor Gray
Write-Host "   - Connect your GitHub repository" -ForegroundColor Gray
Write-Host "   - Select branch: main" -ForegroundColor Gray

Write-Host "`n3. Configure Amplify Environment Variables:" -ForegroundColor White
Write-Host "   Copy values from .env.production.template to Amplify Console" -ForegroundColor Gray

Write-Host "`n4. Configure Backend Environment Variables:" -ForegroundColor White
Write-Host "   Go to EB Console → Your Environment → Configuration → Software" -ForegroundColor Gray
Write-Host "   Add all required environment variables" -ForegroundColor Gray

# Create deployment summary
$summary = @"
# Tubby AI Deployment Summary

## Backend (Elastic Beanstalk)
- Environment: $EnvironmentName
- URL: $backendUrl
- Health Check: $backendUrl/health

## Frontend (Amplify)
- Repository: Your GitHub repo
- Build Config: amplify.yml
- Environment Variables: .env.production.template

## Next Steps
1. Push code to GitHub
2. Set up Amplify in AWS Console
3. Configure environment variables
4. Test the application

## Environment Variables to Configure

### Backend (EB Console)
- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY
- GOOGLE_CLIENT_ID
- GOOGLE_CLIENT_SECRET
- GITHUB_CLIENT_ID
- GITHUB_CLIENT_SECRET
- STRIPE_SECRET_KEY
- STRIPE_PUBLISHABLE_KEY
- SECRET_KEY
- ALLOWED_ORIGINS (include your Amplify domain)

### Frontend (Amplify Console)
- VITE_API_URL: $backendUrl
- VITE_SUPABASE_URL
- VITE_SUPABASE_ANON_KEY
- VITE_GOOGLE_CLIENT_ID
- VITE_GITHUB_CLIENT_ID
- VITE_STRIPE_PUBLISHABLE_KEY

## Testing
- Backend: curl $backendUrl/health
- Frontend: Visit your Amplify URL
- Integration: Test OAuth and API calls
"@

$summary | Out-File -FilePath "DEPLOYMENT_SUMMARY.md" -Encoding UTF8
Write-Host "`n📄 Created DEPLOYMENT_SUMMARY.md with complete instructions" -ForegroundColor Green

Write-Host "`n🎉 Deployment setup completed!" -ForegroundColor Green
Write-Host "📋 Follow the instructions above to complete the deployment" -ForegroundColor Yellow
Write-Host "📄 Check DEPLOYMENT_SUMMARY.md for detailed steps" -ForegroundColor Cyan 