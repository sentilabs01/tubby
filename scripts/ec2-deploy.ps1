# EC2 Direct Deployment for TubbyAI
param(
    [string]$Environment = "production",
    [string]$InstanceType = "t2.micro",
    [string]$KeyPairName = "tubby-key"
)

Write-Host "TubbyAI EC2 Direct Deployment" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Configuration
$PROJECT_ROOT = $PSScriptRoot | Split-Path
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"
$STACK_NAME = "tubby-ec2-$Environment-$TIMESTAMP"

# Check prerequisites
try {
    $awsVersion = aws --version 2>$null
    Write-Host "AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "AWS CLI not available" -ForegroundColor Red
    exit 1
}

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow

$TEMP_DIR = Join-Path $PROJECT_ROOT "ec2-deploy-$TIMESTAMP"
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

# Copy application files
Write-Host "  Copying application files..." -ForegroundColor Cyan
Copy-Item "$BACKEND_DIR\application.py" $TEMP_DIR
Copy-Item "$BACKEND_DIR\requirements_simple.txt" "$TEMP_DIR\requirements.txt"

# Create systemd service file
$SERVICE_FILE = @'
[Unit]
Description=TubbyAI Flask Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/tubby
Environment=PATH=/home/ubuntu/tubby/venv/bin
ExecStart=/home/ubuntu/tubby/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 120 application:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
'@

$SERVICE_FILE | Out-File -FilePath (Join-Path $TEMP_DIR "tubby.service") -Encoding UTF8

# Create deployment script
$DEPLOY_SCRIPT = @'
#!/bin/bash
set -e

echo "Starting TubbyAI deployment..."

# Update system
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv nginx

# Create application directory
sudo mkdir -p /home/ubuntu/tubby
sudo chown ubuntu:ubuntu /home/ubuntu/tubby

# Copy application files
cp -r /tmp/tubby/* /home/ubuntu/tubby/
cd /home/ubuntu/tubby

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Setup systemd service
sudo cp tubby.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable tubby
sudo systemctl start tubby

# Setup nginx
sudo tee /etc/nginx/sites-available/tubby <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/tubby /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

echo "Deployment completed successfully!"
echo "Application is running on http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
'@

$DEPLOY_SCRIPT | Out-File -FilePath (Join-Path $TEMP_DIR "deploy.sh") -Encoding UTF8

# Create CloudFormation template
$CF_TEMPLATE = @'
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "TubbyAI EC2 Deployment Stack",
  "Parameters": {
    "KeyPairName": {
      "Type": "AWS::EC2::KeyPair::KeyName",
      "Description": "Name of an existing EC2 KeyPair"
    },
    "InstanceType": {
      "Type": "String",
      "Default": "t2.micro",
      "Description": "EC2 instance type"
    }
  },
  "Resources": {
    "SecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "Security group for TubbyAI",
        "SecurityGroupIngress": [
          {
            "IpProtocol": "tcp",
            "FromPort": "22",
            "ToPort": "22",
            "CidrIp": "0.0.0.0/0"
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "80",
            "ToPort": "80",
            "CidrIp": "0.0.0.0/0"
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "443",
            "ToPort": "443",
            "CidrIp": "0.0.0.0/0"
          }
        ]
      }
    },
    "EC2Instance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-0c02fb55956c7d316",
        "InstanceType": { "Ref": "InstanceType" },
        "KeyName": { "Ref": "KeyPairName" },
        "SecurityGroupIds": [{ "Ref": "SecurityGroup" }],
        "UserData": {
          "Fn::Base64": {
            "Fn::Join": ["", [
              "#!/bin/bash\n",
              "yum update -y\n",
              "yum install -y python3 python3-pip nginx\n",
              "systemctl enable nginx\n",
              "systemctl start nginx\n",
              "mkdir -p /home/ec2-user/tubby\n",
              "cd /home/ec2-user/tubby\n",
              "python3 -m venv venv\n",
              "source venv/bin/activate\n",
              "pip install gunicorn flask\n",
              "echo 'from flask import Flask\napp = Flask(__name__)\n@app.route(\"/\")\ndef hello():\n    return \"Hello World from TubbyAI!\"\n@app.route(\"/health\")\ndef health():\n    return \"OK\"' > application.py\n",
              "echo 'web: gunicorn --bind 0.0.0.0:5000 application:app' > Procfile\n",
              "nohup gunicorn --bind 0.0.0.0:5000 application:app > app.log 2>&1 &\n",
              "echo 'server {\n    listen 80;\n    location / {\n        proxy_pass http://127.0.0.1:5000;\n        proxy_set_header Host \$host;\n        proxy_set_header X-Real-IP \$remote_addr;\n    }\n}' > /etc/nginx/conf.d/tubby.conf\n",
              "systemctl restart nginx\n"
            ]]
          }
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "TubbyAI-Server"
          },
          {
            "Key": "Environment",
            "Value": "' + $Environment + '"
          }
        ]
      }
    }
  },
  "Outputs": {
    "PublicIP": {
      "Description": "Public IP address of the EC2 instance",
      "Value": { "Fn::GetAtt": ["EC2Instance", "PublicIp"] }
    },
    "PublicDNS": {
      "Description": "Public DNS name of the EC2 instance",
      "Value": { "Fn::GetAtt": ["EC2Instance", "PublicDnsName"] }
    }
  }
}
'@

$CF_TEMPLATE | Out-File -FilePath (Join-Path $TEMP_DIR "cloudformation.json") -Encoding UTF8

# Create ZIP package
Write-Host "  Creating deployment package..." -ForegroundColor Cyan
$ZIP_FILE = Join-Path $PROJECT_ROOT "tubby-ec2-$TIMESTAMP.zip"
Compress-Archive -Path "$TEMP_DIR\*" -DestinationPath $ZIP_FILE -Force

# Deploy using CloudFormation
Write-Host "Deploying to EC2 via CloudFormation..." -ForegroundColor Yellow

try {
    # Check if key pair exists
    Write-Host "  Checking key pair..." -ForegroundColor Cyan
    $keyExists = aws ec2 describe-key-pairs --key-names $KeyPairName --region us-east-1 2>$null
    if (-not $keyExists) {
        Write-Host "  Creating key pair: $KeyPairName" -ForegroundColor Yellow
        aws ec2 create-key-pair --key-name $KeyPairName --region us-east-1 --query 'KeyMaterial' --output text > "$KeyPairName.pem"
        Write-Host "  Key pair created and saved to $KeyPairName.pem" -ForegroundColor Green
    } else {
        Write-Host "  Key pair exists: $KeyPairName" -ForegroundColor Green
    }

    # Deploy CloudFormation stack
    Write-Host "  Deploying CloudFormation stack..." -ForegroundColor Cyan
    aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://"$TEMP_DIR/cloudformation.json" --parameters ParameterKey=KeyPairName,ParameterValue=$KeyPairName ParameterKey=InstanceType,ParameterValue=$InstanceType --capabilities CAPABILITY_IAM --region us-east-1

    Write-Host "  Waiting for stack creation..." -ForegroundColor Yellow
    aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region us-east-1

    # Get stack outputs
    Write-Host "  Getting deployment information..." -ForegroundColor Cyan
    $stackOutputs = aws cloudformation describe-stacks --stack-name $STACK_NAME --region us-east-1 --query 'Stacks[0].Outputs' --output json | ConvertFrom-Json

    $publicIP = ($stackOutputs | Where-Object { $_.OutputKey -eq "PublicIP" }).OutputValue
    $publicDNS = ($stackOutputs | Where-Object { $_.OutputKey -eq "PublicDNS" }).OutputValue

    Write-Host "  Deployment successful!" -ForegroundColor Green
    Write-Host "  Public IP: $publicIP" -ForegroundColor Cyan
    Write-Host "  Public DNS: $publicDNS" -ForegroundColor Cyan
    Write-Host "  Application URL: http://$publicIP" -ForegroundColor Green
    Write-Host "  Health Check: http://$publicIP/health" -ForegroundColor Green

    # Wait for application to start
    Write-Host "  Waiting for application to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # Test the application
    Write-Host "  Testing application..." -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "http://$publicIP/health" -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✅ Application is responding!" -ForegroundColor Green
            Write-Host "  Response: $($response.Content)" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ⚠️ Application not responding yet, may need more time" -ForegroundColor Yellow
    }

} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup
    Remove-Item $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ZIP_FILE -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "EC2 deployment complete!" -ForegroundColor Green
Write-Host "Stack Name: $STACK_NAME" -ForegroundColor Cyan
Write-Host "To delete the stack: aws cloudformation delete-stack --stack-name $STACK_NAME --region us-east-1" -ForegroundColor Yellow 