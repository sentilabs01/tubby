# Fix ZIP file paths for Unix compatibility
Write-Host "Fixing ZIP file paths for Unix compatibility..." -ForegroundColor Green

# Extract the existing ZIP
Write-Host "Extracting existing ZIP..." -ForegroundColor Yellow
$EXTRACT_DIR = "fix-zip-extract"
if (Test-Path $EXTRACT_DIR) { Remove-Item $EXTRACT_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $EXTRACT_DIR | Out-Null

# Extract the ZIP
Expand-Archive -Path "console-upload\console-hello.zip" -DestinationPath $EXTRACT_DIR

Write-Host "Files extracted:" -ForegroundColor Yellow
Get-ChildItem -Recurse $EXTRACT_DIR | ForEach-Object { Write-Host "  - $($_.FullName.Replace($EXTRACT_DIR, ''))" -ForegroundColor Cyan }

# Create a new directory for the fixed files
$FIXED_DIR = "fixed-zip"
if (Test-Path $FIXED_DIR) { Remove-Item $FIXED_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $FIXED_DIR | Out-Null

# Copy files to the fixed directory (this should normalize paths)
Write-Host "Copying files with normalized paths..." -ForegroundColor Yellow
Copy-Item "$EXTRACT_DIR\*" -Destination $FIXED_DIR -Recurse

# Navigate to fixed directory
Set-Location $FIXED_DIR

# Create new ZIP file
Write-Host "Creating new ZIP with fixed paths..." -ForegroundColor Yellow
$FIXED_ZIP = "fixed-hello-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"

# Try to use 7-Zip if available
$7ZIP_PATH = "C:\Program Files\7-Zip\7z.exe"
if (Test-Path $7ZIP_PATH) {
    Write-Host "Using 7-Zip for Unix-compatible ZIP..." -ForegroundColor Green
    & $7ZIP_PATH a -tzip $FIXED_ZIP * -mx=9
} else {
    Write-Host "7-Zip not found. Using PowerShell..." -ForegroundColor Yellow
    Compress-Archive -Path * -DestinationPath $FIXED_ZIP -Force
}

Write-Host "Fixed ZIP created: $FIXED_ZIP" -ForegroundColor Green

# Go back to original directory
Set-Location ..

# Copy the fixed ZIP to a convenient location
Copy-Item "$FIXED_DIR\$FIXED_ZIP" "fixed-hello.zip"

Write-Host ""
Write-Host "Fixed ZIP file ready: fixed-hello.zip" -ForegroundColor Green
Write-Host "Upload this file through AWS Console!" -ForegroundColor Yellow

# Cleanup
Remove-Item $EXTRACT_DIR -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $FIXED_DIR -Recurse -Force -ErrorAction SilentlyContinue 