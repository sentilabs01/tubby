# Create Clean Repository Script
# This script creates a completely new repository without secret history

Write-Host "Creating Clean Repository" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

Write-Host "`nThis script will create a completely new repository without any secret history." -ForegroundColor Yellow
Write-Host "WARNING: This will create a new repository and you'll lose the old commit history!" -ForegroundColor Red

$confirm = Read-Host "`nDo you want to continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nStep 1: Creating backup of current state..." -ForegroundColor Yellow
# Create a backup of current files
$backupDir = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir | Out-Null
Copy-Item -Path "*" -Destination $backupDir -Recurse -Force -Exclude ".git", "node_modules", "dist", "assets"

Write-Host "Backup created in: $backupDir" -ForegroundColor Green

Write-Host "`nStep 2: Removing files with secrets..." -ForegroundColor Yellow
# Remove files that contain secrets
$secretFiles = @(
    "scripts/amplify-env*.json",
    "scripts/setup-amplify-env.bat", 
    "update_stripe_key.ps1",
    "amplify/backend/function/tubbyBackend/function-parameters.json"
)

foreach ($pattern in $secretFiles) {
    Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Remove-Item -Force
    Write-Host "Removed: $pattern" -ForegroundColor Cyan
}

Write-Host "`nStep 3: Updating .gitignore to prevent future secrets..." -ForegroundColor Yellow
# Add secret prevention to .gitignore
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

# Backup directories
backup-*/
"@

Add-Content -Path ".gitignore" -Value $gitignoreAdditions
Write-Host "Updated .gitignore" -ForegroundColor Green

Write-Host "`nStep 4: Creating new git repository..." -ForegroundColor Yellow
# Remove old git history
Remove-Item -Path ".git" -Recurse -Force -ErrorAction SilentlyContinue

# Initialize new repository
git init
git add .
git commit -m "Initial commit - Clean repository without secrets"

Write-Host "`nStep 5: Setting up remote..." -ForegroundColor Yellow
Write-Host "You have two options:" -ForegroundColor Cyan
Write-Host "1. Create a new repository on GitHub" -ForegroundColor White
Write-Host "2. Force push to existing repository (will overwrite history)" -ForegroundColor White

$option = Read-Host "`nChoose option (1 or 2)"
if ($option -eq "1") {
    Write-Host "`nPlease:" -ForegroundColor Yellow
    Write-Host "1. Go to GitHub and create a new repository" -ForegroundColor White
    Write-Host "2. Copy the repository URL" -ForegroundColor White
    Write-Host "3. Run: git remote add origin YOUR_NEW_REPO_URL" -ForegroundColor Cyan
    Write-Host "4. Run: git push -u origin main" -ForegroundColor Cyan
} else {
    $remoteUrl = Read-Host "`nEnter the existing repository URL (e.g., https://github.com/sentilabs01/tubby.git)"
    git remote add origin $remoteUrl
    git push origin main --force
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Successfully pushed clean repository!" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Push failed. You may need to unblock secrets first." -ForegroundColor Red
        Write-Host "Try creating a new repository instead." -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 Clean repository created!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Deploy backend: .\deploy-backend-simple.ps1" -ForegroundColor White
Write-Host "2. Update environment variables in AWS Console" -ForegroundColor White
Write-Host "3. Test the application" -ForegroundColor White

Write-Host "`nBackup location: $backupDir" -ForegroundColor Cyan
Write-Host "If you need to restore anything from the backup, check that directory." -ForegroundColor Yellow 