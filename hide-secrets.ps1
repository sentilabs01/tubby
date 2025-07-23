# Hide Secrets from GitHub Script
# This script removes secrets from git history and pushes clean code

Write-Host "Hiding Secrets from GitHub" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

Write-Host "`nThis script will remove secrets from git history and push clean code." -ForegroundColor Yellow
Write-Host "WARNING: This will rewrite git history!" -ForegroundColor Red

$confirm = Read-Host "`nDo you want to continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nStep 1: Creating backup branch..." -ForegroundColor Yellow
git branch backup-before-secret-cleanup

Write-Host "`nStep 2: Using git filter-branch to remove secrets..." -ForegroundColor Yellow
Write-Host "This will remove files containing secrets from the entire git history." -ForegroundColor Cyan

# Create a script to remove secret files
$filterScript = @"
#!/bin/bash
# Remove files that contain secrets
rm -f scripts/amplify-env*.json
rm -f scripts/setup-amplify-env.bat
rm -f update_stripe_key.ps1
rm -f amplify/backend/function/tubbyBackend/function-parameters.json
"@

$filterScript | Out-File -FilePath "remove-secrets.sh" -Encoding UTF8

Write-Host "`nStep 3: Running git filter-branch..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Cyan

# Use git filter-branch to remove secret files from history
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch scripts/amplify-env*.json scripts/setup-amplify-env.bat update_stripe_key.ps1 amplify/backend/function/tubbyBackend/function-parameters.json" --prune-empty --tag-name-filter cat -- --all

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nStep 4: Cleaning up..." -ForegroundColor Yellow
    # Remove the backup refs
    git for-each-ref --format="%(refname)" refs/original/ | ForEach-Object { git update-ref -d $_ }
    
    # Force garbage collection
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
    
    Write-Host "`nStep 5: Force pushing clean history..." -ForegroundColor Yellow
    Write-Host "WARNING: This will overwrite the remote repository!" -ForegroundColor Red
    
    $forcePush = Read-Host "Do you want to force push the clean history? (y/N)"
    if ($forcePush -eq "y" -or $forcePush -eq "Y") {
        git push origin main --force
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Successfully pushed clean history to GitHub!" -ForegroundColor Green
            Write-Host "Secrets have been removed from the repository." -ForegroundColor Green
        } else {
            Write-Host "`n❌ Force push failed. You may need to unblock secrets first." -ForegroundColor Red
        }
    } else {
        Write-Host "`nSkipping force push. You can do it manually later with:" -ForegroundColor Yellow
        Write-Host "git push origin main --force" -ForegroundColor Cyan
    }
} else {
    Write-Host "`n❌ Git filter-branch failed. Trying alternative approach..." -ForegroundColor Red
    
    Write-Host "`nAlternative: Creating a new clean branch..." -ForegroundColor Yellow
    git checkout --orphan clean-main
    git add .
    git commit -m "Initial clean commit - secrets removed"
    
    Write-Host "`nNow you can:" -ForegroundColor Yellow
    Write-Host "1. Delete the old main branch: git branch -D main" -ForegroundColor Cyan
    Write-Host "2. Rename clean branch: git branch -m main" -ForegroundColor Cyan
    Write-Host "3. Force push: git push origin main --force" -ForegroundColor Cyan
}

Write-Host "`nStep 6: Creating .gitignore to prevent future secrets..." -ForegroundColor Yellow

# Add to .gitignore to prevent future secrets
$gitignoreAdditions = @"

# Prevent secrets from being committed
scripts/amplify-env*.json
scripts/setup-amplify-env.bat
update_stripe_key.ps1
amplify/backend/function/tubbyBackend/function-parameters.json

# Environment files with secrets
.env
.env.local
.env.production
*.env

# Configuration files with secrets
config/secrets.json
secrets.json
"@

Add-Content -Path ".gitignore" -Value $gitignoreAdditions

Write-Host "`n✅ .gitignore updated to prevent future secrets" -ForegroundColor Green

Write-Host "`n🎉 Secret cleanup completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Deploy backend: .\deploy-backend-simple.ps1" -ForegroundColor White
Write-Host "2. Update environment variables in AWS Console" -ForegroundColor White
Write-Host "3. Test the application" -ForegroundColor White

Write-Host "`nIf you need to restore from backup:" -ForegroundColor Yellow
Write-Host "git checkout backup-before-secret-cleanup" -ForegroundColor Cyan 