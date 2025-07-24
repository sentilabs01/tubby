# Create Simple ZIP for AWS Console Upload
Write-Host "Creating simple ZIP for AWS Console upload..." -ForegroundColor Green

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$DEPLOY_DIR = "console-upload"
if (Test-Path $DEPLOY_DIR) { Remove-Item $DEPLOY_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $DEPLOY_DIR | Out-Null

# Copy files
Write-Host "Copying files..." -ForegroundColor Yellow
Copy-Item "backend/hello_world.py" "$DEPLOY_DIR/"
Copy-Item "backend/requirements_simple.txt" "$DEPLOY_DIR/requirements.txt"
Copy-Item "backend/Procfile_hello" "$DEPLOY_DIR/Procfile"

# Create .ebextensions directory
New-Item -ItemType Directory -Path "$DEPLOY_DIR/.ebextensions" | Out-Null
Copy-Item "backend/.ebextensions/02_hello.config" "$DEPLOY_DIR/.ebextensions/"

# Navigate to deploy directory
Set-Location $DEPLOY_DIR

Write-Host "Creating ZIP file..." -ForegroundColor Yellow
$ZIP_FILE = "console-hello.zip"

# Create ZIP file
Compress-Archive -Path * -DestinationPath $ZIP_FILE -Force

Write-Host "ZIP file created: $ZIP_FILE" -ForegroundColor Green
Write-Host "Files included:" -ForegroundColor Yellow
Get-ChildItem -Recurse | ForEach-Object { Write-Host "  - $($_.FullName.Replace($DEPLOY_DIR, ''))" -ForegroundColor Cyan }

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Go to AWS Console → Elastic Beanstalk" -ForegroundColor Yellow
Write-Host "2. Create new environment or update existing" -ForegroundColor Yellow
Write-Host "3. Upload the file: $ZIP_FILE" -ForegroundColor Yellow
Write-Host "4. This file is in: $DEPLOY_DIR\$ZIP_FILE" -ForegroundColor Yellow

# Go back to original directory
Set-Location ..

Write-Host ""
Write-Host "ZIP file ready for manual upload!" -ForegroundColor Green 