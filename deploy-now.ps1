# Quick Production Deployment Script for Tubby AI
# This script creates a production-ready package immediately

Write-Host "🚀 Tubby AI Quick Production Deployment" -ForegroundColor Blue
Write-Host "=" * 50 -ForegroundColor Blue

# Configuration
$ProjectName = "tubby-ai"
$Version = Get-Date -Format "yyyyMMdd-HHmmss"
$PackageName = "$ProjectName-$Version.zip"

Write-Host "📦 Creating deployment package: $PackageName" -ForegroundColor Green

# Step 1: Build Frontend
Write-Host "🔨 Building frontend..." -ForegroundColor Yellow
try {
    npm run build:prod
    Write-Host "✅ Frontend build successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend build failed: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow

# Create package directory
$PackageDir = "deployment-package"
if (Test-Path $PackageDir) {
    Remove-Item -Recurse -Force $PackageDir
}
New-Item -ItemType Directory -Path $PackageDir | Out-Null

# Copy frontend build
Write-Host "📁 Copying frontend files..." -ForegroundColor Yellow
Copy-Item -Path "dist\*" -Destination $PackageDir -Recurse

# Copy backend files
Write-Host "📁 Copying backend files..." -ForegroundColor Yellow
$BackendPackageDir = Join-Path $PackageDir "backend"
New-Item -ItemType Directory -Path $BackendPackageDir | Out-Null
Copy-Item -Path "backend\*" -Destination $BackendPackageDir -Recurse

# Copy configuration files
Write-Host "📁 Copying configuration files..." -ForegroundColor Yellow
Copy-Item -Path "package.json" -Destination $PackageDir -Force
Copy-Item -Path "vite.config.js" -Destination $PackageDir -Force
Copy-Item -Path "amplify.yml" -Destination $PackageDir -Force
Copy-Item -Path "env.example" -Destination $PackageDir -Force

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

# Create zip package
Write-Host "🗜️ Creating ZIP package..." -ForegroundColor Yellow
try {
    Compress-Archive -Path "$PackageDir\*" -DestinationPath $PackageName -Force
    Write-Host "✅ ZIP package created successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create ZIP package: $_" -ForegroundColor Red
    exit 1
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