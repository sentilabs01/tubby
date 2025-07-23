# Tubby AI Production Deployment Script (PowerShell)
# This script handles both frontend and backend deployment

param(
    [switch]$SkipBuild,
    [switch]$SkipDeploy,
    [string]$Environment = "production"
)

# Configuration
$FrontendDir = "."
$BackendDir = "backend"
$ProjectName = "tubby-ai"
$Version = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "🚀 Starting Tubby AI Production Deployment v$Version" -ForegroundColor Blue

# Function to print status
function Write-Status {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Check if required tools are installed
function Test-Dependencies {
    Write-Status "Checking dependencies..."
    
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Error "Node.js is not installed"
        exit 1
    }
    
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Error "npm is not installed"
        exit 1
    }
    
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "git is not installed"
        exit 1
    }
    
    Write-Status "All dependencies found"
}

# Build frontend
function Build-Frontend {
    Write-Status "Building frontend..."
    
    Push-Location $FrontendDir
    
    # Clean previous build
    if (Test-Path "dist") {
        Remove-Item -Recurse -Force "dist"
        Write-Status "Cleaned previous build"
    }
    
    # Install dependencies
    Write-Status "Installing frontend dependencies..."
    npm ci --production=false
    
    # Build for production
    Write-Status "Building for production..."
    npm run build:prod
    
    # Verify build
    if (-not (Test-Path "dist")) {
        Write-Error "Frontend build failed - dist directory not found"
        exit 1
    }
    
    Write-Status "Frontend built successfully"
    Pop-Location
}

# Build backend
function Build-Backend {
    Write-Status "Building backend..."
    
    Push-Location $BackendDir
    
    # Check if requirements files exist
    if (-not (Test-Path "requirements_production.txt")) {
        Write-Error "Backend requirements file not found"
        exit 1
    }
    
    # Create virtual environment if it doesn't exist
    if (-not (Test-Path "venv")) {
        Write-Status "Creating Python virtual environment..."
        python -m venv venv
    }
    
    # Activate virtual environment
    Write-Status "Activating virtual environment..."
    & ".\venv\Scripts\Activate.ps1"
    
    # Install dependencies
    Write-Status "Installing backend dependencies..."
    pip install -r requirements_production.txt
    
    # Test backend
    Write-Status "Testing backend..."
    python -c "import flask; print('Flask imported successfully')"
    
    Pop-Location
    
    Write-Status "Backend prepared successfully"
}

# Deploy to AWS Amplify (Frontend)
function Deploy-FrontendAmplify {
    Write-Status "Deploying frontend to AWS Amplify..."
    
    # Check if Amplify CLI is installed
    if (-not (Get-Command amplify -ErrorAction SilentlyContinue)) {
        Write-Warning "Amplify CLI not found. Installing..."
        npm install -g @aws-amplify/cli
    }
    
    # Check if project is initialized
    if (-not (Test-Path "amplify\.config\local-env-info.json")) {
        Write-Warning "Amplify project not initialized. Please run: amplify init"
        Write-Warning "Skipping Amplify deployment"
        return
    }
    
    # Deploy to Amplify
    amplify publish --yes
    
    Write-Status "Frontend deployed to Amplify"
}

# Deploy to AWS Elastic Beanstalk (Backend)
function Deploy-BackendEB {
    Write-Status "Deploying backend to AWS Elastic Beanstalk..."
    
    Push-Location $BackendDir
    
    # Check if EB CLI is installed
    if (-not (Get-Command eb -ErrorAction SilentlyContinue)) {
        Write-Warning "EB CLI not found. Installing..."
        pip install awsebcli
    }
    
    # Check if EB project is initialized
    if (-not (Test-Path ".elasticbeanstalk\config.yml")) {
        Write-Warning "EB project not initialized. Please run: eb init"
        Write-Warning "Skipping EB deployment"
        Pop-Location
        return
    }
    
    # Deploy to EB
    eb deploy --timeout 20
    
    Pop-Location
    
    Write-Status "Backend deployed to Elastic Beanstalk"
}

# Create deployment package
function New-DeploymentPackage {
    Write-Status "Creating deployment package..."
    
    $PackageName = "$ProjectName-$Version.zip"
    
    # Create package directory
    $PackageDir = "deployment-package"
    if (Test-Path $PackageDir) {
        Remove-Item -Recurse -Force $PackageDir
    }
    New-Item -ItemType Directory -Path $PackageDir | Out-Null
    
    # Copy frontend build
    Copy-Item -Path "dist\*" -Destination $PackageDir -Recurse
    
    # Copy backend files
    $BackendPackageDir = Join-Path $PackageDir "backend"
    New-Item -ItemType Directory -Path $BackendPackageDir | Out-Null
    Copy-Item -Path "backend\*" -Destination $BackendPackageDir -Recurse
    
    # Copy configuration files
    Copy-Item -Path "package.json" -Destination $PackageDir
    Copy-Item -Path "vite.config.js" -Destination $PackageDir
    Copy-Item -Path "amplify.yml" -Destination $PackageDir
    
    # Create deployment info
    $DeploymentInfo = @"
Tubby AI Deployment Package
Version: $Version
Build Time: $(Get-Date)
Environment: $Environment
Frontend: Built with Vite
Backend: Flask with Gunicorn
"@
    
    $DeploymentInfo | Out-File -FilePath (Join-Path $PackageDir "DEPLOYMENT_INFO.txt") -Encoding UTF8
    
    # Create zip package
    Compress-Archive -Path "$PackageDir\*" -DestinationPath $PackageName -Force
    
    # Clean up
    Remove-Item -Recurse -Force $PackageDir
    
    Write-Status "Deployment package created: $PackageName"
}

# Health check
function Test-Health {
    Write-Status "Performing health checks..."
    
    # Frontend health check
    if (Test-Path "dist") {
        if (Test-Path "dist\index.html") {
            Write-Status "Frontend build verified"
        } else {
            Write-Error "Frontend build incomplete"
            return $false
        }
    } else {
        Write-Error "Frontend build not found"
        return $false
    }
    
    # Backend health check
    if (Test-Path "backend\app.py") {
        Write-Status "Backend files verified"
    } else {
        Write-Error "Backend files not found"
        return $false
    }
    
    Write-Status "All health checks passed"
    return $true
}

# Main deployment flow
function Start-Deployment {
    Write-Host "Starting deployment process..." -ForegroundColor Blue
    
    # Check dependencies
    Test-Dependencies
    
    if (-not $SkipBuild) {
        # Build applications
        Build-Frontend
        Build-Backend
        
        # Health checks
        if (-not (Test-Health)) {
            Write-Error "Health checks failed"
            exit 1
        }
    }
    
    # Create deployment package
    New-DeploymentPackage
    
    if (-not $SkipDeploy) {
        # Deploy (optional - uncomment if you want automatic deployment)
        # Deploy-FrontendAmplify
        # Deploy-BackendEB
    }
    
    Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
    Write-Host "Deployment package: $ProjectName-$Version.zip" -ForegroundColor Blue
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Upload the deployment package to your hosting provider" -ForegroundColor White
    Write-Host "  2. Configure environment variables" -ForegroundColor White
    Write-Host "  3. Start the application" -ForegroundColor White
    Write-Host "  4. Run health checks" -ForegroundColor White
}

# Run main function
Start-Deployment 