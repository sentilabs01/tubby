# Update Production Environment Variables for Tubby AI
# This script helps you update the VITE_API_URL in AWS Amplify

Write-Host "Updating Production Environment Variables for Tubby AI" -ForegroundColor Green
Write-Host ""

# Check if AWS CLI is installed
try {
    aws --version | Out-Null
    Write-Host "AWS CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "AWS CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Get Amplify App ID
Write-Host "Please enter your Amplify App ID:" -ForegroundColor Yellow
Write-Host "You can find this in the AWS Amplify Console URL or app settings" -ForegroundColor Gray
$APP_ID = Read-Host "App ID"

if (-not $APP_ID) {
    Write-Host "App ID is required" -ForegroundColor Red
    exit 1
}

# Get region
Write-Host "Please enter your AWS region (e.g., us-east-1):" -ForegroundColor Yellow
$REGION = Read-Host "Region"

if (-not $REGION) {
    Write-Host "Region is required" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Updating environment variables..." -ForegroundColor Blue

# Update VITE_API_URL to point to the backend
try {
    aws amplify update-app --app-id $APP_ID --region $REGION --environment-variables VITE_API_URL=https://api.tubbyai.com
    Write-Host "Successfully updated VITE_API_URL to https://api.tubbyai.com" -ForegroundColor Green
} catch {
    Write-Host "Failed to update VITE_API_URL" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Environment variables updated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Go to AWS Amplify Console: https://console.aws.amazon.com/amplify/" -ForegroundColor White
Write-Host "2. Select your Tubby AI app" -ForegroundColor White
Write-Host "3. Go to App Settings -> Environment Variables" -ForegroundColor White
Write-Host "4. Verify VITE_API_URL is set to: https://api.tubbyai.com" -ForegroundColor White
Write-Host "5. Redeploy your app if needed" -ForegroundColor White
Write-Host ""
Write-Host "Your app should now correctly connect to the backend!" -ForegroundColor Green 