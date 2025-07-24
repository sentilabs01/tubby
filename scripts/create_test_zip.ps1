# Create Test ZIP for AWS Elastic Beanstalk
Write-Host "Creating ZIP file for AWS Elastic Beanstalk upload..." -ForegroundColor Green

# Create temp directory
$TEMP_DIR = "temp-eb-upload"
if (Test-Path $TEMP_DIR) { Remove-Item $TEMP_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $TEMP_DIR | Out-Null

# Copy and rename files
Copy-Item "backend/ultra_minimal_test.py" "$TEMP_DIR/"
Copy-Item "backend/requirements_ultra_minimal.txt" "$TEMP_DIR/requirements.txt"
Copy-Item "backend/Procfile_ultra_minimal" "$TEMP_DIR/Procfile"

# Create ZIP file
$ZIP_FILE = "tubby-test-app.zip"
if (Test-Path $ZIP_FILE) { Remove-Item $ZIP_FILE -Force }

Compress-Archive -Path "$TEMP_DIR/*" -DestinationPath $ZIP_FILE

Write-Host "ZIP file created: $ZIP_FILE" -ForegroundColor Green
Write-Host "Files included:" -ForegroundColor Yellow
Get-ChildItem $TEMP_DIR | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Cyan }

# Cleanup temp directory
Remove-Item $TEMP_DIR -Recurse -Force

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Click 'Next' in AWS Console" -ForegroundColor Yellow
Write-Host "2. Select 'Upload your code'" -ForegroundColor Yellow
Write-Host "3. Upload the file: $ZIP_FILE" -ForegroundColor Yellow
Write-Host "4. Continue with the wizard" -ForegroundColor Yellow 