# Clean Git History Script
# This script helps remove secrets from git history

Write-Host "Cleaning Git History of Secrets" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

Write-Host "`nThis script will help you remove secrets from git history." -ForegroundColor Yellow
Write-Host "WARNING: This will rewrite git history!" -ForegroundColor Red
Write-Host "Make sure you have a backup or are okay with losing the commit history." -ForegroundColor Red

$confirm = Read-Host "`nDo you want to continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nStep 1: Creating a backup branch..." -ForegroundColor Yellow
git branch backup-before-cleanup

Write-Host "`nStep 2: Interactive rebase to remove secrets..." -ForegroundColor Yellow
Write-Host "This will open an interactive rebase editor." -ForegroundColor Cyan
Write-Host "You'll need to:" -ForegroundColor White
Write-Host "1. Find commits with secrets (around commit 2a86997)" -ForegroundColor White
Write-Host "2. Change 'pick' to 'edit' for those commits" -ForegroundColor White
Write-Host "3. Remove the secret files during the edit" -ForegroundColor White
Write-Host "4. Continue the rebase" -ForegroundColor White

$startCommit = Read-Host "`nEnter the commit hash to start rebasing from (default: 2a86997)"
if (-not $startCommit) {
    $startCommit = "2a86997"
}

Write-Host "`nStarting interactive rebase from $startCommit..." -ForegroundColor Yellow
Write-Host "This will open an editor. Follow the instructions above." -ForegroundColor Cyan

# Start interactive rebase
git rebase -i $startCommit

Write-Host "`nStep 3: Force push to update remote..." -ForegroundColor Yellow
Write-Host "WARNING: This will overwrite the remote history!" -ForegroundColor Red
$forcePush = Read-Host "Do you want to force push? (y/N)"
if ($forcePush -eq "y" -or $forcePush -eq "Y") {
    git push origin main --force
    Write-Host "Force push completed!" -ForegroundColor Green
} else {
    Write-Host "Skipping force push. You can do it manually later with:" -ForegroundColor Yellow
    Write-Host "git push origin main --force" -ForegroundColor Cyan
}

Write-Host "`nCleanup completed!" -ForegroundColor Green
Write-Host "If you need to restore from backup:" -ForegroundColor Yellow
Write-Host "git checkout backup-before-cleanup" -ForegroundColor Cyan 