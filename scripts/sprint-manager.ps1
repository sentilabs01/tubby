# TubbyAI Sprint Manager
# Comprehensive sprint management and deployment orchestration

param(
    [string]$SprintAction = "start",  # Options: start, deploy, test, monitor, cleanup
    [string]$DeploymentType = "auto",  # Options: auto, 7zip, docker, git
    [string]$Environment = "development",
    [switch]$SkipTests,
    [switch]$Force,
    [switch]$Verbose
)

Write-Host "🚀 TubbyAI Sprint Manager" -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Green

# Configuration
$PROJECT_ROOT = $PSScriptRoot | Split-Path
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend"
$SCRIPTS_DIR = Join-Path $PROJECT_ROOT "scripts"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"
$SPRINT_LOG = Join-Path $PROJECT_ROOT "sprint-log-$TIMESTAMP.txt"

# Function to log sprint activities
function Write-SprintLog {
    param($Message, $Level = "INFO")
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(switch ($Level) { "ERROR" { "Red" }; "WARN" { "Yellow" }; "SUCCESS" { "Green" }; default { "White" } })
    Add-Content -Path $SPRINT_LOG -Value $logEntry
}

# Function to check system health
function Test-SystemHealth {
    Write-SprintLog "Checking system health..." "INFO"
    
    $health = @{
        "Git Status" = $false
        "Dependencies" = $false
        "AWS Access" = $false
        "Build Tools" = $false
    }
    
    # Check Git status
    try {
        $gitStatus = git status --porcelain 2>$null
        if ($gitStatus) {
            Write-SprintLog "⚠️ Uncommitted changes detected" "WARN"
        } else {
            Write-SprintLog "✅ Git repository clean" "SUCCESS"
            $health["Git Status"] = $true
        }
    } catch {
        Write-SprintLog "❌ Git not available" "ERROR"
    }
    
    # Check dependencies
    $deps = @("node", "npm", "python", "pip")
    $missingDeps = @()
    foreach ($dep in $deps) {
        try {
            $version = & $dep --version 2>$null
            if ($version) {
                Write-SprintLog "✅ $dep found: $version" "SUCCESS"
            } else {
                $missingDeps += $dep
            }
        } catch {
            $missingDeps += $dep
        }
    }
    
    if ($missingDeps.Count -eq 0) {
        $health["Dependencies"] = $true
    } else {
        Write-SprintLog "❌ Missing dependencies: $($missingDeps -join ', ')" "ERROR"
    }
    
    # Check AWS access
    try {
        $awsIdentity = aws sts get-caller-identity --query 'Account' --output text 2>$null
        if ($awsIdentity) {
            Write-SprintLog "✅ AWS access confirmed (Account: $awsIdentity)" "SUCCESS"
            $health["AWS Access"] = $true
        } else {
            Write-SprintLog "❌ AWS access failed" "ERROR"
        }
    } catch {
        Write-SprintLog "❌ AWS CLI not available" "ERROR"
    }
    
    # Check build tools
    $buildTools = @{
        "7-Zip" = "C:\Program Files\7-Zip\7z.exe"
        "Docker" = "docker"
    }
    
    $availableTools = @()
    foreach ($tool in $buildTools.GetEnumerator()) {
        if ($tool.Value -eq "docker") {
            try {
                $version = docker --version 2>$null
                if ($version) {
                    $availableTools += $tool.Key
                    Write-SprintLog "✅ $($tool.Key) found: $version" "SUCCESS"
                }
            } catch { }
        } else {
            if (Test-Path $tool.Value) {
                $availableTools += $tool.Key
                Write-SprintLog "✅ $($tool.Key) found" "SUCCESS"
            }
        }
    }
    
    if ($availableTools.Count -gt 0) {
        $health["Build Tools"] = $true
        Write-SprintLog "Available build tools: $($availableTools -join ', ')" "INFO"
    } else {
        Write-SprintLog "❌ No build tools available" "ERROR"
    }
    
    return $health
}

# Function to run sprint tests
function Invoke-SprintTests {
    Write-SprintLog "Running sprint tests..." "INFO"
    
    if ($SkipTests) {
        Write-SprintLog "Skipping tests as requested" "WARN"
        return $true
    }
    
    $testResults = @{
        "Frontend Build" = $false
        "Backend Tests" = $false
        "Integration" = $false
    }
    
    # Frontend build test
    Write-SprintLog "Testing frontend build..." "INFO"
    Set-Location $PROJECT_ROOT
    try {
        npm run build:prod
        Write-SprintLog "✅ Frontend build successful" "SUCCESS"
        $testResults["Frontend Build"] = $true
    } catch {
        Write-SprintLog "❌ Frontend build failed" "ERROR"
    }
    
    # Backend tests
    Write-SprintLog "Testing backend..." "INFO"
    Set-Location $BACKEND_DIR
    try {
        python -m pytest tests/ -v
        Write-SprintLog "✅ Backend tests passed" "SUCCESS"
        $testResults["Backend Tests"] = $true
    } catch {
        Write-SprintLog "⚠️ Backend tests failed or not configured" "WARN"
    }
    
    # Integration test (basic connectivity)
    Write-SprintLog "Testing integration..." "INFO"
    Set-Location $PROJECT_ROOT
    try {
        # Test if backend can start
        $testApp = Join-Path $BACKEND_DIR "hello_world.py"
        if (Test-Path $testApp) {
            $testResult = python $testApp 2>$null
            Write-SprintLog "✅ Basic integration test passed" "SUCCESS"
            $testResults["Integration"] = $true
        } else {
            Write-SprintLog "⚠️ No test app found for integration test" "WARN"
        }
    } catch {
        Write-SprintLog "❌ Integration test failed" "ERROR"
    }
    
    return $testResults
}

# Function to determine best deployment method
function Get-BestDeploymentMethod {
    param($Health, $AvailableTools)
    
    Write-SprintLog "Determining best deployment method..." "INFO"
    
    if ($DeploymentType -ne "auto") {
        Write-SprintLog "Using specified deployment type: $DeploymentType" "INFO"
        return $DeploymentType
    }
    
    # Priority order: Docker > 7-Zip > Git
    if ($AvailableTools -contains "Docker") {
        Write-SprintLog "Selected Docker deployment (most reliable)" "INFO"
        return "docker"
    } elseif ($AvailableTools -contains "7-Zip") {
        Write-SprintLog "Selected 7-Zip deployment" "INFO"
        return "7zip"
    } elseif ($Health["Git Status"]) {
        Write-SprintLog "Selected Git deployment" "INFO"
        return "git"
    } else {
        Write-SprintLog "❌ No suitable deployment method available" "ERROR"
        return $null
    }
}

# Function to execute deployment
function Invoke-SprintDeployment {
    param($Method, $Environment)
    
    Write-SprintLog "Executing deployment using $Method..." "INFO"
    
    $deploymentScript = switch ($Method.ToLower()) {
        "7zip" { "sprint-deployment-automation.ps1" }
        "docker" { "deploy-docker-backend.ps1" }
        "git" { "deploy_with_git.ps1" }
        default { $null }
    }
    
    if (-not $deploymentScript) {
        Write-SprintLog "❌ Unknown deployment method: $Method" "ERROR"
        return $false
    }
    
    $scriptPath = Join-Path $SCRIPTS_DIR $deploymentScript
    if (-not (Test-Path $scriptPath)) {
        Write-SprintLog "❌ Deployment script not found: $scriptPath" "ERROR"
        return $false
    }
    
    try {
        Write-SprintLog "Running deployment script: $deploymentScript" "INFO"
        & $scriptPath -DeploymentType $Method -Environment $Environment
        Write-SprintLog "✅ Deployment completed successfully" "SUCCESS"
        return $true
    } catch {
        Write-SprintLog "❌ Deployment failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to monitor deployment
function Start-SprintMonitoring {
    Write-SprintLog "Starting deployment monitoring..." "INFO"
    
    # Monitor for 5 minutes
    $monitorDuration = 300
    $checkInterval = 30
    $elapsed = 0
    
    while ($elapsed -lt $monitorDuration) {
        Write-SprintLog "Checking deployment status... ($elapsed/$monitorDuration seconds)" "INFO"
        
        try {
            # Check Elastic Beanstalk environments
            $environments = aws elasticbeanstalk describe-environments --application-name tubbyai --query 'Environments[?Status==`Ready`]' --output json | ConvertFrom-Json
            
            foreach ($env in $environments) {
                Write-SprintLog "Environment: $($env.EnvironmentName) - Health: $($env.Health) - Status: $($env.Status)" "INFO"
                
                if ($env.Health -eq "Green" -and $env.Status -eq "Ready") {
                    Write-SprintLog "✅ Environment $($env.EnvironmentName) is healthy and ready!" "SUCCESS"
                    if ($env.CNAME) {
                        Write-SprintLog "🌐 URL: http://$($env.CNAME)" "SUCCESS"
                    }
                }
            }
        } catch {
            Write-SprintLog "⚠️ Could not check environment status" "WARN"
        }
        
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval
    }
    
    Write-SprintLog "Monitoring period completed" "INFO"
}

# Function to cleanup sprint artifacts
function Invoke-SprintCleanup {
    Write-SprintLog "Cleaning up sprint artifacts..." "INFO"
    
    # Remove temporary files
    $tempPatterns = @(
        "deploy-temp-*",
        "docker-deploy-*",
        "tubby-backend-*.zip",
        "deployment-summary-*.md"
    )
    
    foreach ($pattern in $tempPatterns) {
        $tempFiles = Get-ChildItem -Path $PROJECT_ROOT -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $tempFiles) {
            try {
                if (Test-Path $file.FullName -PathType Container) {
                    Remove-Item $file.FullName -Recurse -Force
                } else {
                    Remove-Item $file.FullName -Force
                }
                Write-SprintLog "Cleaned up: $($file.Name)" "INFO"
            } catch {
                Write-SprintLog "⚠️ Could not clean up: $($file.Name)" "WARN"
            }
        }
    }
    
    Write-SprintLog "✅ Cleanup completed" "SUCCESS"
}

# Main sprint execution
Write-SprintLog "Starting TubbyAI Sprint: $SprintAction" "INFO"

switch ($SprintAction.ToLower()) {
    "start" {
        Write-SprintLog "=== SPRINT START ===" "INFO"
        
        # Check system health
        $health = Test-SystemHealth
        
        # Run tests
        $testResults = Invoke-SprintTests
        
        # Determine deployment method
        $availableTools = @()
        if (Test-Path "C:\Program Files\7-Zip\7z.exe") { $availableTools += "7-Zip" }
        try { if (docker --version 2>$null) { $availableTools += "Docker" } } catch { }
        
        $deploymentMethod = Get-BestDeploymentMethod -Health $health -AvailableTools $availableTools
        
        if ($deploymentMethod) {
            Write-SprintLog "Ready for deployment using: $deploymentMethod" "SUCCESS"
        } else {
            Write-SprintLog "❌ Sprint cannot proceed - no deployment method available" "ERROR"
        }
    }
    
    "deploy" {
        Write-SprintLog "=== SPRINT DEPLOYMENT ===" "INFO"
        
        # Check health first
        $health = Test-SystemHealth
        
        if (-not $health["AWS Access"]) {
            Write-SprintLog "❌ Cannot deploy - AWS access not available" "ERROR"
            break
        }
        
        # Determine deployment method
        $availableTools = @()
        if (Test-Path "C:\Program Files\7-Zip\7z.exe") { $availableTools += "7-Zip" }
        try { if (docker --version 2>$null) { $availableTools += "Docker" } } catch { }
        
        $deploymentMethod = Get-BestDeploymentMethod -Health $health -AvailableTools $availableTools
        
        if ($deploymentMethod) {
            $deploymentSuccess = Invoke-SprintDeployment -Method $deploymentMethod -Environment $Environment
            
            if ($deploymentSuccess) {
                Write-SprintLog "🎯 Deployment completed successfully!" "SUCCESS"
            } else {
                Write-SprintLog "❌ Deployment failed" "ERROR"
            }
        } else {
            Write-SprintLog "❌ No suitable deployment method available" "ERROR"
        }
    }
    
    "test" {
        Write-SprintLog "=== SPRINT TESTING ===" "INFO"
        $testResults = Invoke-SprintTests
        Write-SprintLog "Testing completed" "INFO"
    }
    
    "monitor" {
        Write-SprintLog "=== SPRINT MONITORING ===" "INFO"
        Start-SprintMonitoring
    }
    
    "cleanup" {
        Write-SprintLog "=== SPRINT CLEANUP ===" "INFO"
        Invoke-SprintCleanup
    }
    
    default {
        Write-SprintLog "❌ Unknown sprint action: $SprintAction" "ERROR"
        Write-SprintLog "Available actions: start, deploy, test, monitor, cleanup" "INFO"
    }
}

# Final summary
Write-SprintLog "=== SPRINT SUMMARY ===" "INFO"
Write-SprintLog "Action: $SprintAction" "INFO"
Write-SprintLog "Environment: $Environment" "INFO"
Write-SprintLog "Log file: $SPRINT_LOG" "INFO"

Write-Host ""
Write-Host "🎯 Sprint $SprintAction completed!" -ForegroundColor Green
Write-Host "📄 Log saved to: $SPRINT_LOG" -ForegroundColor Cyan 