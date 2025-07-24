# ECS Deployment for TubbyAI
param(
    [string]$ClusterName = "tubby-cluster",
    [string]$ServiceName = "tubby-service"
)

Write-Host "ECS Deployment for TubbyAI" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

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

Write-Host "Deploying to ECS..." -ForegroundColor Yellow

try {
    # Check if cluster exists
    Write-Host "  Checking ECS cluster..." -ForegroundColor Cyan
    $clusterExists = aws ecs describe-clusters --clusters $ClusterName --region us-east-1 --query 'clusters[0].status' --output text 2>$null
    
    if ($clusterExists -eq "ACTIVE") {
        Write-Host "  Cluster exists: $ClusterName" -ForegroundColor Green
    } else {
        Write-Host "  Creating cluster: $ClusterName" -ForegroundColor Yellow
        aws ecs create-cluster --cluster-name $ClusterName --region us-east-1
    }
    
    # Create task definition
    Write-Host "  Creating task definition..." -ForegroundColor Cyan
    
    $taskDefinition = @"
{
    "family": "tubby-task",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "tubby-container",
            "image": "python:3.11-slim",
            "essential": true,
            "portMappings": [
                {
                    "containerPort": 8080,
                    "protocol": "tcp"
                }
            ],
            "command": [
                "sh",
                "-c",
                "pip install flask && python -c \"from flask import Flask; app = Flask(__name__); @app.route('/'); def hello(): return 'Hello from ECS!'; @app.route('/health'); def health(): return 'OK'; app.run(host='0.0.0.0', port=8080)\""
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/tubby-task",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
}
"@
    
    $taskDefinition | Out-File -FilePath "task-definition.json" -Encoding UTF8
    
    # Register task definition
    Write-Host "  Registering task definition..." -ForegroundColor Cyan
    $taskDefArn = aws ecs register-task-definition --cli-input-json file://task-definition.json --region us-east-1 --query 'taskDefinition.taskDefinitionArn' --output text
    
    Write-Host "  Task definition registered: $taskDefArn" -ForegroundColor Green
    
    # Create security group
    Write-Host "  Creating security group..." -ForegroundColor Cyan
    $sgName = "tubby-ecs-sg-$TIMESTAMP"
    $sgId = aws ec2 create-security-group --group-name $sgName --description "Security group for TubbyAI ECS" --region us-east-1 --query 'GroupId' --output text
    
    # Add rules
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 8080 --cidr 0.0.0.0/0 --region us-east-1
    
    # Create service
    Write-Host "  Creating ECS service..." -ForegroundColor Cyan
    
    $serviceConfig = @"
{
    "cluster": "$ClusterName",
    "serviceName": "$ServiceName",
    "taskDefinition": "$taskDefArn",
    "desiredCount": 1,
    "launchType": "FARGATE",
    "networkConfiguration": {
        "awsvpcConfiguration": {
            "subnets": ["subnet-12345678"],
            "securityGroups": ["$sgId"],
            "assignPublicIp": "ENABLED"
        }
    }
}
"@
    
    $serviceConfig | Out-File -FilePath "service-config.json" -Encoding UTF8
    
    # Get default VPC subnets
    Write-Host "  Getting VPC subnets..." -ForegroundColor Cyan
    $subnets = aws ec2 describe-subnets --region us-east-1 --query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId' --output text
    $firstSubnet = ($subnets -split ' ')[0]
    
    # Update service config with actual subnet
    $serviceConfig = $serviceConfig -replace "subnet-12345678", $firstSubnet
    $serviceConfig | Out-File -FilePath "service-config.json" -Encoding UTF8
    
    # Create service
    $serviceResult = aws ecs create-service --cli-input-json file://service-config.json --region us-east-1
    
    Write-Host "  ✅ ECS service created!" -ForegroundColor Green
    
    # Wait for service to be stable
    Write-Host "  Waiting for service to be stable..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
    
    # Get service details
    $serviceInfo = aws ecs describe-services --cluster $ClusterName --services $ServiceName --region us-east-1 --query 'services[0]' --output json | ConvertFrom-Json
    
    Write-Host "  Service Status: $($serviceInfo.status)" -ForegroundColor Cyan
    Write-Host "  Desired Count: $($serviceInfo.desiredCount)" -ForegroundColor Cyan
    Write-Host "  Running Count: $($serviceInfo.runningCount)" -ForegroundColor Cyan
    
    # Get task details
    if ($serviceInfo.runningCount -gt 0) {
        $tasks = aws ecs list-tasks --cluster $ClusterName --service-name $ServiceName --region us-east-1 --query 'taskArns' --output text
        $taskArn = ($tasks -split ' ')[0]
        
        $taskInfo = aws ecs describe-tasks --cluster $ClusterName --tasks $taskArn --region us-east-1 --query 'tasks[0]' --output json | ConvertFrom-Json
        
        Write-Host "  Task Status: $($taskInfo.lastStatus)" -ForegroundColor Cyan
        
        # Get public IP if available
        if ($taskInfo.attachments) {
            $eniId = $taskInfo.attachments[0].details | Where-Object { $_.name -eq "networkInterfaceId" } | Select-Object -ExpandProperty value
            $publicIP = aws ec2 describe-network-interfaces --network-interface-ids $eniId --region us-east-1 --query 'NetworkInterfaces[0].Association.PublicIp' --output text
            
            if ($publicIP -and $publicIP -ne "None") {
                Write-Host "  Public IP: $publicIP" -ForegroundColor Green
                Write-Host "  Service URL: http://$publicIP:8080" -ForegroundColor Green
                
                # Test the service
                Write-Host "  Testing service..." -ForegroundColor Cyan
                Start-Sleep -Seconds 30
                
                try {
                    $response = Invoke-WebRequest -Uri "http://$publicIP:8080/health" -TimeoutSec 10 -UseBasicParsing
                    Write-Host "  ✅ Service is responding!" -ForegroundColor Green
                    Write-Host "  Response: $($response.Content.Trim())" -ForegroundColor Green
                } catch {
                    Write-Host "  ❌ Service not responding yet: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
    
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup temp files
    Remove-Item "task-definition.json" -ErrorAction SilentlyContinue
    Remove-Item "service-config.json" -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "ECS deployment complete!" -ForegroundColor Green
Write-Host "To delete service: aws ecs delete-service --cluster $ClusterName --service $ServiceName --region us-east-1" -ForegroundColor Yellow
Write-Host "To delete cluster: aws ecs delete-cluster --cluster $ClusterName --region us-east-1" -ForegroundColor Yellow 