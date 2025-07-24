# Lambda Deployment for TubbyAI
param(
    [string]$FunctionName = "tubby-lambda"
)

Write-Host "Lambda Deployment for TubbyAI" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

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

Write-Host "Deploying to Lambda..." -ForegroundColor Yellow

try {
    # Create simple Lambda function
    Write-Host "  Creating Lambda function..." -ForegroundColor Cyan
    
    $lambdaCode = @"
import json

def lambda_handler(event, context):
    path = event.get('path', '/')
    
    if path == '/health':
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps('OK')
        }
    elif path == '/test':
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps('Test endpoint working!')
        }
    else:
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps('Hello World from TubbyAI Lambda!')
        }
"@
    
    $lambdaCode | Out-File -FilePath "lambda_function.py" -Encoding UTF8
    
    # Create deployment package
    Write-Host "  Creating deployment package..." -ForegroundColor Cyan
    Compress-Archive -Path "lambda_function.py" -DestinationPath "lambda-deployment.zip" -Force
    
    # Check if function exists
    Write-Host "  Checking existing function..." -ForegroundColor Cyan
    $functionExists = aws lambda get-function --function-name $FunctionName --region us-east-1 2>$null
    
    if ($functionExists) {
        Write-Host "  Updating existing function..." -ForegroundColor Yellow
        aws lambda update-function-code --function-name $FunctionName --zip-file fileb://lambda-deployment.zip --region us-east-1
    } else {
        Write-Host "  Creating new function..." -ForegroundColor Yellow
        
        # Create execution role
        Write-Host "  Creating execution role..." -ForegroundColor Cyan
        $roleName = "tubby-lambda-role-$TIMESTAMP"
        
        $trustPolicy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
"@
        
        $trustPolicy | Out-File -FilePath "trust-policy.json" -Encoding UTF8
        
        $roleArn = aws iam create-role --role-name $roleName --assume-role-policy-document file://trust-policy.json --query 'Role.Arn' --output text
        
        # Attach basic execution policy
        aws iam attach-role-policy --role-name $roleName --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
        
        # Create function
        aws lambda create-function --function-name $FunctionName --runtime python3.11 --role $roleArn --handler lambda_function.lambda_handler --zip-file fileb://lambda-deployment.zip --region us-east-1 --timeout 30 --memory-size 128
    }
    
    Write-Host "  ✅ Lambda function created/updated!" -ForegroundColor Green
    
    # Create API Gateway
    Write-Host "  Creating API Gateway..." -ForegroundColor Cyan
    
    # Create REST API
    $apiName = "tubby-api-$TIMESTAMP"
    $apiId = aws apigateway create-rest-api --name $apiName --region us-east-1 --query 'id' --output text
    
    Write-Host "  API ID: $apiId" -ForegroundColor Cyan
    
    # Get root resource
    $rootId = aws apigateway get-resources --rest-api-id $apiId --region us-east-1 --query 'items[?path==`/`].id' --output text
    
    # Create proxy resource
    $proxyId = aws apigateway create-resource --rest-api-id $apiId --parent-id $rootId --path-part "{proxy+}" --region us-east-1 --query 'id' --output text
    
    # Create methods
    Write-Host "  Creating API methods..." -ForegroundColor Cyan
    
    # GET method on root
    aws apigateway put-method --rest-api-id $apiId --resource-id $rootId --http-method GET --authorization-type NONE --region us-east-1
    
    # GET method on proxy
    aws apigateway put-method --rest-api-id $apiId --resource-id $proxyId --http-method GET --authorization-type NONE --region us-east-1
    
    # Create Lambda integration
    $lambdaUri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:396608803476:function:$FunctionName/invocations"
    
    $integration = @"
{
    "type": "AWS_PROXY",
    "integrationHttpMethod": "POST",
    "uri": "$lambdaUri"
}
"@
    
    $integration | Out-File -FilePath "integration.json" -Encoding UTF8
    
    # Add integration to root
    aws apigateway put-integration --rest-api-id $apiId --resource-id $rootId --http-method GET --type AWS_PROXY --integration-http-method POST --uri $lambdaUri --region us-east-1
    
    # Add integration to proxy
    aws apigateway put-integration --rest-api-id $apiId --resource-id $proxyId --http-method GET --type AWS_PROXY --integration-http-method POST --uri $lambdaUri --region us-east-1
    
    # Deploy API
    Write-Host "  Deploying API..." -ForegroundColor Cyan
    aws apigateway create-deployment --rest-api-id $apiId --stage-name prod --region us-east-1
    
    # Get API URL
    $apiUrl = "https://$apiId.execute-api.us-east-1.amazonaws.com/prod"
    
    Write-Host "  ✅ API Gateway created!" -ForegroundColor Green
    Write-Host "  API URL: $apiUrl" -ForegroundColor Green
    
    # Add Lambda permission
    Write-Host "  Adding Lambda permission..." -ForegroundColor Cyan
    aws lambda add-permission --function-name $FunctionName --statement-id apigateway-prod --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:396608803476:$apiId/*/GET/*" --region us-east-1 2>$null
    
    # Test the API
    Write-Host "  Testing API..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10
    
    try {
        $response = Invoke-WebRequest -Uri "$apiUrl/health" -TimeoutSec 10 -UseBasicParsing
        Write-Host "  ✅ API is responding!" -ForegroundColor Green
        Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "  Response: $($response.Content.Trim())" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ API not responding yet: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Try again in 30 seconds: $apiUrl/health" -ForegroundColor Yellow
    }
    
    # Test root endpoint
    try {
        $response = Invoke-WebRequest -Uri $apiUrl -TimeoutSec 10 -UseBasicParsing
        Write-Host "  ✅ Root endpoint responding!" -ForegroundColor Green
        Write-Host "  Response: $($response.Content.Trim())" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Root endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup temp files
    Remove-Item "lambda_function.py" -ErrorAction SilentlyContinue
    Remove-Item "lambda-deployment.zip" -ErrorAction SilentlyContinue
    Remove-Item "trust-policy.json" -ErrorAction SilentlyContinue
    Remove-Item "integration.json" -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Lambda deployment complete!" -ForegroundColor Green
Write-Host "API URL: $apiUrl" -ForegroundColor Green
Write-Host "Health Check: $apiUrl/health" -ForegroundColor Green
Write-Host "Test Endpoint: $apiUrl/test" -ForegroundColor Green 