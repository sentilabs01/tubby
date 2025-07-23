# Amplify Environment Variables Setup Script (PowerShell)
# This script helps you set environment variables in AWS Amplify

Write-Host "🚀 Setting up Amplify Environment Variables for Tubby AI" -ForegroundColor Green

# Check if AWS CLI is installed
try {
    aws --version | Out-Null
    Write-Host "✅ AWS CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" -ForegroundColor Yellow
    exit 1
}

# Check if user is logged in
try {
    $caller = aws sts get-caller-identity | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($caller.Arn)" -ForegroundColor Green
} catch {
    Write-Host "❌ You are not logged in to AWS CLI. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Set app ID directly
$APP_ID = "d34pheadvyr3df"
$BRANCH = "main"

Write-Host "🔧 Setting up environment variables for app: $APP_ID, branch: $BRANCH" -ForegroundColor Yellow

# Function to set environment variable
function Set-EnvVar {
    param($Key, $Value)
    Write-Host "Setting $Key..." -ForegroundColor Cyan
    try {
        aws amplify update-app --app-id $APP_ID --environment-variables "$Key=$Value"
        Write-Host "✅ Set $Key" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to set $Key" -ForegroundColor Red
    }
}

# Frontend Variables
Set-EnvVar "VITE_API_URL" "https://tubbyai.com"

# Backend Variables
Set-EnvVar "FLASK_ENV" "production"
Set-EnvVar "SECRET_KEY" "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"
Set-EnvVar "PORT" "5004"
Set-EnvVar "HOST" "0.0.0.0"

# Supabase Configuration
Set-EnvVar "SUPABASE_URL" "https://ewrbezytnhuovvmkepeg.supabase.co"
Set-EnvVar "SUPABASE_ANON_KEY" "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3cmJlenl0bmh1b3Z2bWtlcGVnIiwicm9sZSI6ImFub2"
Set-EnvVar "SUPABASE_SERVICE_ROLE_KEY" "your-supabase-service-role-key"

# OAuth Configuration
Set-EnvVar "GOOGLE_CLIENT_ID" "117261848322-rgs0fd2fsk2emdgcd0jhjv4380rcmibh.apps.googleusercontent.com"
Set-EnvVar "GOOGLE_CLIENT_SECRET" "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"
Set-EnvVar "GITHUB_CLIENT_ID" "Ov231i0VjZz21dCiQ9oj"
Set-EnvVar "GITHUB_CLIENT_SECRET" "21962b4c088c2d402bb45209c929b58ab93f88ec"

# Stripe Configuration
Set-EnvVar "STRIPE_PUBLISHABLE_KEY" "pk_live_51RnFitKoB6ANfJLNwqnyzDzOsUMH2Ie6b7SBOvZucOAUFkyPo0PqCsqZmLZq2Kqpzp3qLQa65KQ0jlrLWP3kXSRp00A1NZSjVt"
Set-EnvVar "STRIPE_SECRET_KEY" "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"
Set-EnvVar "STRIPE_WEBHOOK_SECRET" "your-stripe-webhook-secret"
Set-EnvVar "STRIPE_BASIC_PRICE_ID" "price_1RnI7vKoB6ANfJLNft6upLIC"
Set-EnvVar "STRIPE_PRO_PRICE_ID" "price_1RnI8LBKoB6ANfJLNRNUyRVIX"
Set-EnvVar "STRIPE_ENTERPRISE_PRICE_ID" "price_1RnI9FKoB6ANfJLNwZTZ5M8A"

# Redis Configuration
Set-EnvVar "REDIS_HOST" "your-redis-host"
Set-EnvVar "REDIS_PORT" "6379"

# Container URLs
Set-EnvVar "GEMINI_CLI_URL_1" "http://localhost:8001"
Set-EnvVar "GEMINI_CLI_URL_2" "http://localhost:8002"

# CORS Configuration
Set-EnvVar "ALLOWED_ORIGINS" "https://tubbyai.com,http://localhost:3001"
Set-EnvVar "BACKEND_URL" "https://api.tubbyai.com"
Set-EnvVar "FRONTEND_URL" "https://tubbyai.com"

Write-Host "✅ Environment variables have been set!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Update the placeholder values with your actual credentials" -ForegroundColor White
Write-Host "2. Redeploy your app in the Amplify console" -ForegroundColor White
Write-Host "3. Test the OAuth authentication flow" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Amplify Console: https://console.aws.amazon.com/amplify/" -ForegroundColor Cyan 