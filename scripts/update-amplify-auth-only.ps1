# Update Amplify Environment Variables for Authentication Only
# This script updates only the Supabase URL needed for OAuth

$AMPLIFY_APP_ID = "d2qjqjqjqjqjqjqjqjqj"
$BRANCH_NAME = "main"

# Supabase URL for OAuth (no secrets, just the URL)
$SUPABASE_URL = "https://bemssfbadcfrvsbgjlua.supabase.co"

Write-Host "Updating Amplify environment variables for authentication..." -ForegroundColor Green

# Create environment variables JSON
$envVars = @{
    VITE_SUPABASE_URL = $SUPABASE_URL
} | ConvertTo-Json

Write-Host "Environment variables to update:" -ForegroundColor Yellow
Write-Host $envVars -ForegroundColor Cyan

# Update Amplify environment variables
try {
    aws amplify update-app --app-id $AMPLIFY_APP_ID --environment-variables $envVars
    
    Write-Host "✅ Successfully updated Amplify environment variables!" -ForegroundColor Green
    Write-Host "🔗 Supabase URL: $SUPABASE_URL" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Failed to update Amplify environment variables:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Push your code changes to GitHub (after removing secrets)" -ForegroundColor White
Write-Host "2. Amplify will automatically rebuild with the new environment variables" -ForegroundColor White
Write-Host "3. Test authentication at https://tubbyai.com" -ForegroundColor White 