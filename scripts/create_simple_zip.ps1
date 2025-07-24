# Create Simple ZIP for AWS Elastic Beanstalk
Write-Host "Creating simple ZIP file for AWS Elastic Beanstalk upload..." -ForegroundColor Green

# Create temp directory
$TEMP_DIR = "temp-simple-upload"
if (Test-Path $TEMP_DIR) { Remove-Item $TEMP_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $TEMP_DIR | Out-Null

# Copy and rename files
Copy-Item "backend/simple_working_test.py" "$TEMP_DIR/"
Copy-Item "backend/requirements_simple.txt" "$TEMP_DIR/requirements.txt"
Copy-Item "backend/Procfile_simple" "$TEMP_DIR/Procfile"

# Create ZIP file
$ZIP_FILE = "tubby-simple-test.zip"
if (Test-Path $ZIP_FILE) { Remove-Item $ZIP_FILE -Force }

Compress-Archive -Path "$TEMP_DIR/*" -DestinationPath $ZIP_FILE

Write-Host "ZIP file created: $ZIP_FILE" -ForegroundColor Green
Write-Host "Files included:" -ForegroundColor Yellow
Get-ChildItem $TEMP_DIR | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Cyan }

# Cleanup temp directory
Remove-Item $TEMP_DIR -Recurse -Force

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Go to AWS Console → Elastic Beanstalk" -ForegroundColor Yellow
Write-Host "2. Create new environment or update existing" -ForegroundColor Yellow
Write-Host "3. Upload the file: $ZIP_FILE" -ForegroundColor Yellow
Write-Host "4. This should work without 502 errors" -ForegroundColor Yellow 