# Create EB Working ZIP for AWS Elastic Beanstalk
Write-Host "Creating EB working ZIP file for AWS Elastic Beanstalk upload..." -ForegroundColor Green

# Create temp directory
$TEMP_DIR = "temp-eb-working"
if (Test-Path $TEMP_DIR) { Remove-Item $TEMP_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $TEMP_DIR | Out-Null

# Copy files
Copy-Item "backend/eb_working_app.py" "$TEMP_DIR/"
Copy-Item "backend/requirements_simple.txt" "$TEMP_DIR/requirements.txt"
Copy-Item "backend/Procfile_eb" "$TEMP_DIR/Procfile"

# Create .ebextensions directory and copy config
New-Item -ItemType Directory -Path "$TEMP_DIR/.ebextensions" | Out-Null
Copy-Item "backend/.ebextensions/01_flask.config" "$TEMP_DIR/.ebextensions/"

# Create ZIP file
$ZIP_FILE = "tubby-eb-working.zip"
if (Test-Path $ZIP_FILE) { Remove-Item $ZIP_FILE -Force }

Compress-Archive -Path "$TEMP_DIR/*" -DestinationPath $ZIP_FILE

Write-Host "ZIP file created: $ZIP_FILE" -ForegroundColor Green
Write-Host "Files included:" -ForegroundColor Yellow
Get-ChildItem $TEMP_DIR -Recurse | ForEach-Object { Write-Host "  - $($_.FullName.Replace($TEMP_DIR, ''))" -ForegroundColor Cyan }

# Cleanup temp directory
Remove-Item $TEMP_DIR -Recurse -Force

Write-Host ""
Write-Host "This version includes:" -ForegroundColor Green
Write-Host "- Proper Elastic Beanstalk configuration" -ForegroundColor Yellow
Write-Host "- Correct WSGIPath setting" -ForegroundColor Yellow
Write-Host "- Environment variable handling" -ForegroundColor Yellow
Write-Host "- Should fix the 502 error" -ForegroundColor Yellow

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Go to AWS Console → Elastic Beanstalk" -ForegroundColor Yellow
Write-Host "2. Upload the file: $ZIP_FILE" -ForegroundColor Yellow
Write-Host "3. This should work without 502 errors" -ForegroundColor Yellow 