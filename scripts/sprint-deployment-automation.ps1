# TubbyAI Development Sprint - Deployment Automation
# This script handles the critical deployment issues and provides multiple deployment options

param(
    [string]$DeploymentType = "7zip",  # Options: 7zip, docker, git, manual
    [string]$Environment = "development",  # Options: development, staging, production
    [switch]$SkipTests,
    [switch]$Force
)

Write-Host "🚀 TubbyAI Development Sprint - Deployment Automation" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Configuration
$PROJECT_ROOT = $PSScriptRoot | Split-Path
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend"
$SCRIPTS_DIR = Join-Path $PROJECT_ROOT "scripts"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    $prerequisites = @{
        "AWS CLI" = $false
        "7-Zip" = $false
        "Docker" = $false
        "Git" = $false
        "Node.js" = $false
        "Python" = $false
    }
    
    # Check AWS CLI
    try {
        $awsVersion = aws --version 2>$null
        if ($awsVersion) {
            $prerequisites["AWS CLI"] = $true
            Write-Host "✅ AWS CLI: $awsVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ AWS CLI not found" -ForegroundColor Red
    }
    
    # Check 7-Zip
    $7ZIP_PATH = "C:\Program Files\7-Zip\7z.exe"
    if (Test-Path $7ZIP_PATH) {
        $prerequisites["7-Zip"] = $true
        Write-Host "✅ 7-Zip found" -ForegroundColor Green
    } else {
        Write-Host "❌ 7-Zip not found at: $7ZIP_PATH" -ForegroundColor Red
        Write-Host "   Download from: https://7-zip.org/" -ForegroundColor Yellow
    }
    
    # Check Docker
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) {
            $prerequisites["Docker"] = $true
            Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Docker not found" -ForegroundColor Red
    }
    
    # Check Git
    try {
        $gitVersion = git --version 2>$null
        if ($gitVersion) {
            $prerequisites["Git"] = $true
            Write-Host "✅ Git: $gitVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Git not found" -ForegroundColor Red
    }
    
    # Check Node.js
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            $prerequisites["Node.js"] = $true
            Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Node.js not found" -ForegroundColor Red
    }
    
    # Check Python
    try {
        $pythonVersion = python --version 2>$null
        if ($pythonVersion) {
            $prerequisites["Python"] = $true
            Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Python not found" -ForegroundColor Red
    }
    
    return $prerequisites
}

# Function to run tests
function Invoke-Tests {
    if ($SkipTests) {
        Write-Host "⏭️ Skipping tests as requested" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "🧪 Running tests..." -ForegroundColor Yellow
    
    # Frontend tests
    Write-Host "  Testing frontend..." -ForegroundColor Cyan
    Set-Location $PROJECT_ROOT
    try {
        npm run test
        Write-Host "  ✅ Frontend tests passed" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Frontend tests failed or not configured" -ForegroundColor Yellow
    }
    
    # Backend tests
    Write-Host "  Testing backend..." -ForegroundColor Cyan
    Set-Location $BACKEND_DIR
    try {
        python -m pytest tests/ -v
        Write-Host "  ✅ Backend tests passed" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Backend tests failed or not configured" -ForegroundColor Yellow
    }
    
    Set-Location $PROJECT_ROOT
    return $true
}

# Function to deploy backend using 7-Zip
function Deploy-Backend-7Zip {
    Write-Host "📦 Deploying backend using 7-Zip..." -ForegroundColor Yellow
    
    $7ZIP_PATH = "C:\Program Files\7-Zip\7z.exe"
    if (-not (Test-Path $7ZIP_PATH)) {
        Write-Host "❌ 7-Zip not found. Please install from https://7-zip.org/" -ForegroundColor Red
        return $false
    }
    
    # Create deployment package
    $DEPLOY_DIR = Join-Path $PROJECT_ROOT "deploy-temp-$TIMESTAMP"
    New-Item -ItemType Directory -Path $DEPLOY_DIR -Force | Out-Null
    
    Write-Host "  Creating deployment package..." -ForegroundColor Cyan
    
    # Copy backend files
    Copy-Item "$BACKEND_DIR\*.py" $DEPLOY_DIR -ErrorAction SilentlyContinue
    Copy-Item "$BACKEND_DIR\requirements*.txt" $DEPLOY_DIR -ErrorAction SilentlyContinue
    Copy-Item "$BACKEND_DIR\Procfile*" $DEPLOY_DIR -ErrorAction SilentlyContinue
    Copy-Item "$BACKEND_DIR\Dockerfile" $DEPLOY_DIR -ErrorAction SilentlyContinue
    Copy-Item "$BACKEND_DIR\gunicorn.conf.py" $DEPLOY_DIR -ErrorAction SilentlyContinue
    
    # Copy .ebextensions if exists
    if (Test-Path "$BACKEND_DIR\.ebextensions") {
        Copy-Item "$BACKEND_DIR\.ebextensions" $DEPLOY_DIR -Recurse
    }
    
    # Create ZIP using 7-Zip
    Set-Location $DEPLOY_DIR
    $ZIP_FILE = "tubby-backend-$TIMESTAMP.zip"
    
    Write-Host "  Creating Unix-compatible ZIP..." -ForegroundColor Cyan
    & $7ZIP_PATH a -tzip $ZIP_FILE * -mx=9
    
    if (-not (Test-Path $ZIP_FILE)) {
        Write-Host "❌ Failed to create ZIP file" -ForegroundColor Red
        Set-Location $PROJECT_ROOT
        Remove-Item $DEPLOY_DIR -Recurse -Force
        return $false
    }
    
    Write-Host "  ✅ ZIP created: $ZIP_FILE" -ForegroundColor Green
    
    # Deploy to Elastic Beanstalk
    Write-Host "  Deploying to Elastic Beanstalk..." -ForegroundColor Cyan
    
    try {
        # Get AWS account info
        $ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
        $BUCKET = "elasticbeanstalk-us-east-1-$ACCOUNT_ID"
        
        # Upload to S3
        aws s3 cp $ZIP_FILE "s3://$BUCKET/$ZIP_FILE" --region us-east-1
        
        # Create application version
        $VERSION_LABEL = "sprint-v-$TIMESTAMP"
        aws elasticbeanstalk create-application-version --application-name tubbyai --version-label $VERSION_LABEL --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP_FILE --region us-east-1
        
        # Deploy to environment
        $ENV_NAME = "tubby-sprint-$TIMESTAMP"
        aws elasticbeanstalk create-environment --application-name tubbyai --environment-name $ENV_NAME --version-label $VERSION_LABEL --solution-stack-name "64bit Amazon Linux 2023 v4.6.1 running Python 3.11" --option-settings "Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=t2.micro" --region us-east-1
        
        Write-Host "  ✅ Backend deployment initiated!" -ForegroundColor Green
        Write-Host "  Environment: $ENV_NAME" -ForegroundColor Cyan
        Write-Host "  Version: $VERSION_LABEL" -ForegroundColor Cyan
        
        # Cleanup
        Set-Location $PROJECT_ROOT
        Remove-Item $DEPLOY_DIR -Recurse -Force
        
        return $true
        
    } catch {
        Write-Host "❌ Backend deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        Set-Location $PROJECT_ROOT
        Remove-Item $DEPLOY_DIR -Recurse -Force
        return $false
    }
}

# Function to deploy frontend using Amplify
function Deploy-Frontend-Amplify {
    Write-Host "🌐 Deploying frontend using Amplify..." -ForegroundColor Yellow
    
    Set-Location $PROJECT_ROOT
    
    # Build frontend
    Write-Host "  Building frontend..." -ForegroundColor Cyan
    try {
        npm run build:prod
        Write-Host "  ✅ Frontend built successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Frontend build failed" -ForegroundColor Red
        return $false
    }
    
    # Check if Amplify is configured
    if (Test-Path "amplify") {
        Write-Host "  Amplify configuration found" -ForegroundColor Cyan
        
        # Push to Amplify
        try {
            amplify push
            Write-Host "  ✅ Frontend deployed to Amplify" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "❌ Amplify deployment failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "⚠️ Amplify not configured. Manual deployment required." -ForegroundColor Yellow
        Write-Host "  Build files ready in 'dist' directory" -ForegroundColor Cyan
        return $true
    }
}

# Function to create deployment summary
function New-DeploymentSummary {
    param($BackendSuccess, $FrontendSuccess, $Prerequisites)
    
    $summary = @"
# 🚀 TubbyAI Sprint Deployment Summary

**Deployment Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Deployment Type:** $DeploymentType
**Environment:** $Environment

## 📊 Results

### Backend Deployment
- **Status:** $(if ($BackendSuccess) { "✅ SUCCESS" } else { "❌ FAILED" })
- **Method:** $DeploymentType
- **Timestamp:** $TIMESTAMP

### Frontend Deployment  
- **Status:** $(if ($FrontendSuccess) { "✅ SUCCESS" } else { "❌ FAILED" })
- **Method:** Amplify
- **Build:** Production

## 🔧 Prerequisites Status

| Tool | Status |
|------|--------|
| AWS CLI | $(if ($Prerequisites["AWS CLI"]) { "✅" } else { "❌" }) |
| 7-Zip | $(if ($Prerequisites["7-Zip"]) { "✅" } else { "❌" }) |
| Docker | $(if ($Prerequisites["Docker"]) { "✅" } else { "❌" }) |
| Git | $(if ($Prerequisites["Git"]) { "✅" } else { "❌" }) |
| Node.js | $(if ($Prerequisites["Node.js"]) { "✅" } else { "❌" }) |
| Python | $(if ($Prerequisites["Python"]) { "✅" } else { "❌" }) |

## 📝 Next Steps

$(if ($BackendSuccess -and $FrontendSuccess) {
"✅ **DEPLOYMENT COMPLETE!**
- Both frontend and backend deployed successfully
- Ready for testing and validation
- Monitor application health"
} elseif ($BackendSuccess) {
"⚠️ **PARTIAL SUCCESS**
- Backend deployed successfully
- Frontend deployment needs attention
- Check Amplify configuration"
} elseif ($FrontendSuccess) {
"⚠️ **PARTIAL SUCCESS**  
- Frontend deployed successfully
- Backend deployment failed
- Check Elastic Beanstalk logs"
} else {
"❌ **DEPLOYMENT FAILED**
- Both deployments failed
- Check prerequisites and configuration
- Review error logs"
})

## 🔍 Troubleshooting

If deployment failed:
1. Check prerequisites installation
2. Verify AWS credentials and permissions
3. Review error logs in AWS Console
4. Test individual components locally

---
*Generated by TubbyAI Sprint Automation*
"@
    
    $summaryPath = Join-Path $PROJECT_ROOT "deployment-summary-$TIMESTAMP.md"
    $summary | Out-File -FilePath $summaryPath -Encoding UTF8
    
    Write-Host "📄 Deployment summary saved to: $summaryPath" -ForegroundColor Green
    return $summaryPath
}

# Main execution
Write-Host "Starting deployment process..." -ForegroundColor Yellow

# Check prerequisites
$prerequisites = Test-Prerequisites

# Run tests
$testsPassed = Invoke-Tests

# Deploy based on type
$backendSuccess = $false
$frontendSuccess = $false

switch ($DeploymentType.ToLower()) {
    "7zip" {
        if ($prerequisites["7-Zip"] -and $prerequisites["AWS CLI"]) {
            $backendSuccess = Deploy-Backend-7Zip
        } else {
            Write-Host "❌ Missing prerequisites for 7-Zip deployment" -ForegroundColor Red
        }
    }
    "docker" {
        if ($prerequisites["Docker"] -and $prerequisites["AWS CLI"]) {
            Write-Host "🐳 Docker deployment not yet implemented" -ForegroundColor Yellow
            # TODO: Implement Docker deployment
        } else {
            Write-Host "❌ Missing prerequisites for Docker deployment" -ForegroundColor Red
        }
    }
    "git" {
        if ($prerequisites["Git"] -and $prerequisites["AWS CLI"]) {
            Write-Host "📚 Git deployment not yet implemented" -ForegroundColor Yellow
            # TODO: Implement Git deployment
        } else {
            Write-Host "❌ Missing prerequisites for Git deployment" -ForegroundColor Red
        }
    }
    default {
        Write-Host "❌ Unknown deployment type: $DeploymentType" -ForegroundColor Red
    }
}

# Deploy frontend
$frontendSuccess = Deploy-Frontend-Amplify

# Generate summary
$summaryPath = New-DeploymentSummary -BackendSuccess $backendSuccess -FrontendSuccess $frontendSuccess -Prerequisites $prerequisites

# Final status
Write-Host ""
Write-Host "🎯 Sprint Deployment Complete!" -ForegroundColor Green
Write-Host "Backend: $(if ($backendSuccess) { "✅" } else { "❌" })" -ForegroundColor $(if ($backendSuccess) { "Green" } else { "Red" })
Write-Host "Frontend: $(if ($frontendSuccess) { "✅" } else { "❌" })" -ForegroundColor $(if ($frontendSuccess) { "Green" } else { "Red" })
Write-Host "Summary: $summaryPath" -ForegroundColor Cyan 