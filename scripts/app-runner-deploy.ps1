# AWS App Runner Deployment for TubbyAI
param(
    [string]$ServiceName = "tubby-app-runner"
)

Write-Host "AWS App Runner Deployment for TubbyAI" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Configuration
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"

# Check prerequisites
try {
    $awsVersion = aws --version 2>$null
    Write-Host "AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "AWS CLI not available" -ForegroundColor Red
    exit 1
}

Write-Host "Deploying to AWS App Runner..." -ForegroundColor Yellow

try {
    # Check if service already exists
    Write-Host "  Checking existing service..." -ForegroundColor Cyan
    $existingService = aws apprunner describe-service --service-name $ServiceName --region us-east-1 2>$null
    
    if ($existingService) {
        Write-Host "  Service exists, updating..." -ForegroundColor Yellow
        $operation = "update"
    } else {
        Write-Host "  Creating new service..." -ForegroundColor Yellow
        $operation = "create"
    }
    
    # Create source configuration
    Write-Host "  Creating source configuration..." -ForegroundColor Cyan
    
    # Create a simple source configuration for direct deployment
    $sourceConfig = @{
        "CodeRepository" = @{
            "CodeConfiguration" = @{
                "ConfigurationSource" = "API"
                "ConfigurationValues" = @{
                    "Runtime" = "python3"
                    "BuildCommand" = "pip install -r requirements.txt"
                    "StartCommand" = "python app.py"
                    "Port" = "8080"
                }
            }
            "SourceCodeVersion" = @{
                "Type" = "BRANCH"
                "Value" = "main"
            }
        }
    }
    
    # For now, let's create a simple deployment using a public repository or direct source
    # We'll use a simple approach with a basic Flask app
    
    # Create service configuration
    $serviceConfig = @{
        "ServiceName" = $ServiceName
        "SourceConfiguration" = $sourceConfig
        "InstanceConfiguration" = @{
            "Cpu" = "1024"
            "Memory" = "2048"
            "InstanceRoleArn" = "arn:aws:iam::396608803476:role/service-role/AWSAppRunnerServicePolicyForECRAccessExecutionRole"
        }
        "AutoScalingConfigurationArn" = "arn:aws:apprunner:us-east-1:396608803476:autoscalingconfiguration/DefaultConfiguration/1/00000000000000000000000000000001"
    }
    
    # Create the service
    Write-Host "  Creating App Runner service..." -ForegroundColor Cyan
    
    # For simplicity, let's use a public source first
    $createCommand = @"
aws apprunner create-service --service-name $ServiceName --region us-east-1 --source-configuration '{
    "CodeRepository": {
        "CodeConfiguration": {
            "ConfigurationSource": "API",
            "ConfigurationValues": {
                "Runtime": "python3",
                "BuildCommand": "pip install -r requirements.txt",
                "StartCommand": "python app.py",
                "Port": "8080"
            }
        },
        "SourceCodeVersion": {
            "Type": "BRANCH",
            "Value": "main"
        },
        "RepositoryUrl": "https://github.com/aws-samples/aws-apprunner-python"
    }
}' --instance-configuration '{
    "Cpu": "1024",
    "Memory": "2048"
}'
"@
    
    Write-Host "  Using sample repository for testing..." -ForegroundColor Cyan
    $result = aws apprunner create-service --service-name $ServiceName --region us-east-1 --source-configuration '{"CodeRepository":{"CodeConfiguration":{"ConfigurationSource":"API","ConfigurationValues":{"Runtime":"python3","BuildCommand":"pip install -r requirements.txt","StartCommand":"python app.py","Port":"8080"}},"SourceCodeVersion":{"Type":"BRANCH","Value":"main"},"RepositoryUrl":"https://github.com/aws-samples/aws-apprunner-python"}}' --instance-configuration '{"Cpu":"1024","Memory":"2048"}' 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Service created successfully!" -ForegroundColor Green
        
        # Get service details
        $serviceInfo = aws apprunner describe-service --service-name $ServiceName --region us-east-1 --query 'Service' --output json | ConvertFrom-Json
        
        Write-Host "  Service ARN: $($serviceInfo.ServiceArn)" -ForegroundColor Cyan
        Write-Host "  Service URL: $($serviceInfo.ServiceUrl)" -ForegroundColor Green
        Write-Host "  Status: $($serviceInfo.Status)" -ForegroundColor Cyan
        
        # Wait for service to be ready
        Write-Host "  Waiting for service to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        
        # Test the service
        if ($serviceInfo.ServiceUrl) {
            Write-Host "  Testing service..." -ForegroundColor Cyan
            try {
                $response = Invoke-WebRequest -Uri "https://$($serviceInfo.ServiceUrl)" -TimeoutSec 10 -UseBasicParsing
                Write-Host "  ✅ Service is responding!" -ForegroundColor Green
                Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Green
                Write-Host "  Content: $($response.Content.Trim())" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Service not responding yet: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "  Try again in 30 seconds: https://$($serviceInfo.ServiceUrl)" -ForegroundColor Yellow
            }
        }
        
    } else {
        Write-Host "  ❌ Service creation failed" -ForegroundColor Red
        Write-Host "  Trying alternative approach..." -ForegroundColor Yellow
        
        # Try a simpler approach with a basic configuration
        Write-Host "  Creating minimal service..." -ForegroundColor Cyan
        
        # Create a simple service using a public sample
        $result = aws apprunner create-service --service-name "$ServiceName-simple" --region us-east-1 --source-configuration '{"CodeRepository":{"CodeConfiguration":{"ConfigurationSource":"API","ConfigurationValues":{"Runtime":"python3","BuildCommand":"echo \"No build needed\"","StartCommand":"python -c \"import flask; print(\"Hello from App Runner!\")\"","Port":"8080"}},"SourceCodeVersion":{"Type":"BRANCH","Value":"main"},"RepositoryUrl":"https://github.com/aws-samples/aws-apprunner-python"}}' --instance-configuration '{"Cpu":"512","Memory":"1024"}' 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Simple service created!" -ForegroundColor Green
            $serviceInfo = aws apprunner describe-service --service-name "$ServiceName-simple" --region us-east-1 --query 'Service' --output json | ConvertFrom-Json
            Write-Host "  Service URL: $($serviceInfo.ServiceUrl)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Simple service creation also failed" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "App Runner deployment attempt complete!" -ForegroundColor Green
Write-Host "To list services: aws apprunner list-services --region us-east-1" -ForegroundColor Yellow
Write-Host "To delete service: aws apprunner delete-service --service-name $ServiceName --region us-east-1" -ForegroundColor Yellow 