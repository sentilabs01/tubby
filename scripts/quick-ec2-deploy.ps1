# Quick EC2 Deployment for TubbyAI
param(
    [string]$InstanceType = "t2.micro",
    [string]$KeyPairName = "tubby-quick-key"
)

Write-Host "TubbyAI Quick EC2 Deployment" -ForegroundColor Green
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

Write-Host "Deploying to EC2..." -ForegroundColor Yellow

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

    # Create security group
    Write-Host "  Creating security group..." -ForegroundColor Cyan
    $sgName = "tubby-sg-$TIMESTAMP"
    $sgId = aws ec2 create-security-group --group-name $sgName --description "Security group for TubbyAI" --region us-east-1 --query 'GroupId' --output text
    
    # Add rules to security group
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0 --region us-east-1
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 80 --cidr 0.0.0.0/0 --region us-east-1
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 443 --cidr 0.0.0.0/0 --region us-east-1

    # Launch EC2 instance with user data
    Write-Host "  Launching EC2 instance..." -ForegroundColor Cyan
    
    $userData = @'
#!/bin/bash
yum update -y
yum install -y python3 python3-pip nginx git

# Start nginx
systemctl enable nginx
systemctl start nginx

# Create application directory
mkdir -p /home/ec2-user/tubby
cd /home/ec2-user/tubby

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install flask gunicorn

# Create application
cat > application.py << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello World from TubbyAI!'

@app.route('/health')
def health():
    return 'OK'

@app.route('/test')
def test():
    return 'Test endpoint working!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Start application with gunicorn
nohup gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 120 application:app > app.log 2>&1 &

# Configure nginx
cat > /etc/nginx/conf.d/tubby.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Remove default nginx config
rm -f /etc/nginx/conf.d/default.conf

# Restart nginx
systemctl restart nginx

echo "Deployment completed!"
echo "Application is running on http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
'@

    # Encode user data
    $encodedUserData = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($userData))

    # Launch instance
    $instanceId = aws ec2 run-instances --image-id ami-0c02fb55956c7d316 --count 1 --instance-type $InstanceType --key-name $KeyPairName --security-group-ids $sgId --user-data $encodedUserData --region us-east-1 --query 'Instances[0].InstanceId' --output text

    Write-Host "  Instance launched: $instanceId" -ForegroundColor Green

    # Wait for instance to be running
    Write-Host "  Waiting for instance to be running..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $instanceId --region us-east-1

    # Get public IP
    $publicIP = aws ec2 describe-instances --instance-ids $instanceId --region us-east-1 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

    Write-Host "  Instance is running!" -ForegroundColor Green
    Write-Host "  Public IP: $publicIP" -ForegroundColor Cyan
    Write-Host "  Application URL: http://$publicIP" -ForegroundColor Green
    Write-Host "  Health Check: http://$publicIP/health" -ForegroundColor Green

    # Wait for application to start
    Write-Host "  Waiting for application to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 45

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
        Write-Host "  Try again in 30 seconds: http://$publicIP/health" -ForegroundColor Yellow
    }

    # Save deployment info
    $deploymentInfo = @{
        InstanceId = $instanceId
        PublicIP = $publicIP
        SecurityGroupId = $sgId
        KeyPairName = $KeyPairName
        DeployedAt = Get-Date
    }

    $deploymentInfo | ConvertTo-Json | Out-File -FilePath "ec2-deployment-$TIMESTAMP.json"

    Write-Host ""
    Write-Host "Quick EC2 deployment complete!" -ForegroundColor Green
    Write-Host "Deployment info saved to: ec2-deployment-$TIMESTAMP.json" -ForegroundColor Cyan
    Write-Host "To connect via SSH: ssh -i $KeyPairName.pem ec2-user@$publicIP" -ForegroundColor Yellow
    Write-Host "To terminate instance: aws ec2 terminate-instances --instance-ids $instanceId --region us-east-1" -ForegroundColor Yellow

} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
} 