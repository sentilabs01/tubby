# Simple Production Deployment Script for Tubby AI
Write-Host "🚀 Tubby AI Production Deployment" -ForegroundColor Blue

# Configuration
$ProjectName = "tubby-ai"
$Version = Get-Date -Format "yyyyMMdd-HHmmss"
$PackageName = "$ProjectName-$Version.zip"

Write-Host "📦 Creating package: $PackageName" -ForegroundColor Green

# Step 1: Build Frontend
Write-Host "🔨 Building frontend..." -ForegroundColor Yellow
npm run build:prod
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Frontend build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Frontend build successful" -ForegroundColor Green

# Step 2: Create deployment directory
Write-Host "📁 Creating deployment package..." -ForegroundColor Yellow
$PackageDir = "deployment-package"

# Clean up existing directory
if (Test-Path $PackageDir) {
    Remove-Item -Recurse -Force $PackageDir
}

# Create new directory
New-Item -ItemType Directory -Path $PackageDir | Out-Null

# Copy frontend files
Write-Host "📁 Copying frontend files..." -ForegroundColor Yellow
Get-ChildItem -Path "dist" -Recurse | ForEach-Object {
    $Destination = $_.FullName.Replace("$PWD\dist", "$PWD\$PackageDir")
    if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    } else {
        Copy-Item $_.FullName -Destination $Destination -Force
    }
}

# Copy backend files
Write-Host "📁 Copying backend files..." -ForegroundColor Yellow
$BackendDir = Join-Path $PackageDir "backend"
New-Item -ItemType Directory -Path $BackendDir | Out-Null
Get-ChildItem -Path "backend" -Recurse | ForEach-Object {
    $Destination = $_.FullName.Replace("$PWD\backend", "$PWD\$BackendDir")
    if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    } else {
        Copy-Item $_.FullName -Destination $Destination -Force
    }
}

# Copy configuration files
Write-Host "📁 Copying configuration files..." -ForegroundColor Yellow
Copy-Item "package.json" -Destination $PackageDir -Force
Copy-Item "vite.config.js" -Destination $PackageDir -Force
Copy-Item "amplify.yml" -Destination $PackageDir -Force
Copy-Item "env.example" -Destination $PackageDir -Force

# Create deployment info
$DeploymentInfo = @"
Tubby AI Production Deployment Package
=====================================
Version: $Version
Build Time: $(Get-Date)
Environment: Production

Frontend:
- Built with Vite
- Code splitting enabled
- Minified and optimized
- Offline mode support

Backend:
- Flask with Gunicorn
- Eventlet worker class
- WebSocket support
- Health checks included

Deployment Instructions:
1. Extract this package to your server
2. Configure environment variables (see env.example)
3. Install backend dependencies: pip install -r backend/requirements_production.txt
4. Start backend: python backend/start_production.py
5. Serve frontend files with a web server (nginx, Apache, etc.)

Health Check:
- Frontend: Check if index.html loads
- Backend: curl http://localhost:5004/health

Offline Mode:
- Automatically detects backend status
- Provides graceful degradation
- Can be manually enabled/disabled

Support:
- Check PRODUCTION_DEPLOYMENT_GUIDE.md for detailed instructions
- Review logs for troubleshooting
"@

$DeploymentInfo | Out-File -FilePath (Join-Path $PackageDir "DEPLOYMENT_INFO.txt") -Encoding UTF8

# Create ZIP using 7-Zip if available, otherwise use PowerShell
Write-Host "🗜️ Creating ZIP package..." -ForegroundColor Yellow

# Try to use 7-Zip if available
$7zPath = "C:\Program Files\7-Zip\7z.exe"
if (Test-Path $7zPath) {
    & $7zPath a -tzip $PackageName "$PackageDir\*"
    Write-Host "✅ ZIP package created with 7-Zip" -ForegroundColor Green
} else {
    # Use PowerShell Compress-Archive with error handling
    try {
        $null = Compress-Archive -Path "$PackageDir\*" -DestinationPath $PackageName -Force -ErrorAction Stop
        Write-Host "✅ ZIP package created with PowerShell" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create ZIP package: $_" -ForegroundColor Red
        Write-Host "💡 Try installing 7-Zip or manually zip the deployment-package folder" -ForegroundColor Yellow
        exit 1
    }
}

# Clean up
if (Test-Path $PackageDir) {
    Remove-Item -Recurse -Force $PackageDir
    Write-Host "🧹 Cleaned up temporary files" -ForegroundColor Green
}

# Display results
if (Test-Path $PackageName) {
    $PackageSize = (Get-Item $PackageName).Length / 1MB
    Write-Host "🎉 Deployment package created successfully!" -ForegroundColor Green
    Write-Host "📦 Package: $PackageName" -ForegroundColor Blue
    Write-Host "📏 Size: $([math]::Round($PackageSize, 2)) MB" -ForegroundColor Blue
} else {
    Write-Host "❌ Package creation failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Upload $PackageName to your hosting provider" -ForegroundColor White
Write-Host "2. Extract and configure environment variables" -ForegroundColor White
Write-Host "3. Start the backend server" -ForegroundColor White
Write-Host "4. Configure web server for frontend" -ForegroundColor White
Write-Host "5. Test the application" -ForegroundColor White

Write-Host "`n📚 For detailed instructions, see PRODUCTION_DEPLOYMENT_GUIDE.md" -ForegroundColor Cyan 