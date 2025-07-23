# Deploy Authentication Fix
# This script removes secrets and pushes the OAuth fix to production

Write-Host "🚀 Deploying Authentication Fix..." -ForegroundColor Green

# Step 1: Remove secret files
Write-Host "🗑️ Removing secret files..." -ForegroundColor Yellow

$secretFiles = @(
    "scripts/amplify-env-complete.json",
    "scripts/amplify-env-updated.json", 
    "scripts/amplify-env.json",
    "scripts/setup-amplify-env.bat",
    "update_stripe_key.ps1",
    "amplify/backend/function/tubbyBackend/function-parameters.json"
)

foreach ($file in $secretFiles) {
    if (Test-Path $file) {
        Write-Host "Removing: $file" -ForegroundColor Red
        git rm $file
    } else {
        Write-Host "File not found: $file" -ForegroundColor Gray
    }
}

# Step 2: Add all changes
Write-Host "📦 Adding changes..." -ForegroundColor Yellow
git add .

# Step 3: Commit changes
Write-Host "💾 Committing changes..." -ForegroundColor Yellow
git commit -m "Fix OAuth authentication - remove secrets and use frontend-only processing"

# Step 4: Push to GitHub
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Yellow
try {
    git push origin auth-fix-clean
    Write-Host "✅ Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "🔄 Amplify will automatically rebuild and deploy..." -ForegroundColor Cyan
} catch {
    Write-Host "❌ Failed to push: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 You may need to allow secrets in GitHub first:" -ForegroundColor Yellow
    Write-Host "   Go to the URLs in the error message and click 'Allow'" -ForegroundColor White
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Wait for Amplify to rebuild (usually 2-3 minutes)" -ForegroundColor White
Write-Host "2. Test authentication at https://tubbyai.com" -ForegroundColor White
Write-Host "3. OAuth should now work without backend dependency" -ForegroundColor White 