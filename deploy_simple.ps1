# Simple Deployment Script
# Creates a new branch without secrets and pushes it

Write-Host "🚀 Creating new branch for deployment..." -ForegroundColor Green

# Create new branch
git checkout -b auth-fix-simple

# Add all changes
git add .

# Commit
git commit -m "Fix authentication - frontend only mode"

# Push new branch
Write-Host "🚀 Pushing to new branch..." -ForegroundColor Yellow
try {
    git push origin auth-fix-simple
    Write-Host "✅ Successfully pushed to auth-fix-simple branch!" -ForegroundColor Green
    Write-Host "🔄 Amplify will automatically rebuild..." -ForegroundColor Cyan
} catch {
    Write-Host "❌ Failed to push: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Go to AWS Amplify Console" -ForegroundColor White
Write-Host "2. Switch to auth-fix-simple branch" -ForegroundColor White
Write-Host "3. Wait for rebuild to complete" -ForegroundColor White
Write-Host "4. Test authentication at https://tubbyai.com" -ForegroundColor White 