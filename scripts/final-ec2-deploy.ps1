# Final EC2 Deployment for TubbyAI
param(
    [string]$InstanceType = "t2.micro"
)

Write-Host "TubbyAI Final EC2 Deployment" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Configuration
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"
$KEY_NAME = "tubby-final-key-$TIMESTAMP"

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
    # Create key pair
    Write-Host "  Creating key pair..." -ForegroundColor Cyan
    aws ec2 create-key-pair --key-name $KEY_NAME --region us-east-1 --query 'KeyMaterial' --output text > "$KEY_NAME.pem"
    Write-Host "  Key pair created: $KEY_NAME.pem" -ForegroundColor Green

    # Create security group
    Write-Host "  Creating security group..." -ForegroundColor Cyan
    $sgName = "tubby-final-sg-$TIMESTAMP"
    $sgId = aws ec2 create-security-group --group-name $sgName --description "Security group for TubbyAI" --region us-east-1 --query 'GroupId' --output text
    
    # Add rules to security group
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0 --region us-east-1
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 80 --cidr 0.0.0.0/0 --region us-east-1

    # Launch EC2 instance with Amazon Linux 2
    Write-Host "  Launching EC2 instance..." -ForegroundColor Cyan
    
    $userData = @'
#!/bin/bash
yum update -y
yum install -y python3 python3-pip nginx

# Start nginx
systemctl enable nginx
systemctl start nginx

# Create simple test page
echo "Hello from TubbyAI!" > /var/www/html/index.html
echo "Health check OK" > /var/www/html/health

# Create Python app
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

cat > app.py << 'EOF'
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

# Install Flask and start app
pip3 install flask
nohup python3 app.py > app.log 2>&1 &

# Configure nginx to proxy to Flask
cat > /etc/nginx/conf.d/app.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

systemctl restart nginx

echo "Deployment completed at $(date)" > /tmp/deployment.log
'@

    # Encode user data
    $encodedUserData = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($userData))

    # Launch instance with Amazon Linux 2 AMI
    $instanceId = aws ec2 run-instances --image-id ami-02b3c03c6fadb6e2c --count 1 --instance-type $InstanceType --key-name $KEY_NAME --security-group-ids $sgId --user-data $encodedUserData --region us-east-1 --query 'Instances[0].InstanceId' --output text

    Write-Host "  Instance launched: $instanceId" -ForegroundColor Green

    # Wait for instance to be running
    Write-Host "  Waiting for instance to be running..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $instanceId --region us-east-1

    # Wait for status checks
    Write-Host "  Waiting for status checks..." -ForegroundColor Yellow
    aws ec2 wait instance-status-ok --instance-ids $instanceId --region us-east-1

    # Get public IP
    $publicIP = aws ec2 describe-instances --instance-ids $instanceId --region us-east-1 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

    Write-Host "  Instance is ready!" -ForegroundColor Green
    Write-Host "  Public IP: $publicIP" -ForegroundColor Cyan
    Write-Host "  Application URL: http://$publicIP" -ForegroundColor Green
    Write-Host "  Health Check: http://$publicIP/health" -ForegroundColor Green

    # Wait for application to start
    Write-Host "  Waiting for application to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 90

    # Test the application
    Write-Host "  Testing application..." -ForegroundColor Cyan
    
    # Test nginx first
    try {
        $response = Invoke-WebRequest -Uri "http://$publicIP" -TimeoutSec 10
        Write-Host "  ✅ Nginx is responding!" -ForegroundColor Green
        Write-Host "  Response: $($response.Content)" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Nginx not responding" -ForegroundColor Red
    }

    # Test Flask app
    try {
        $response = Invoke-WebRequest -Uri "http://$publicIP/health" -TimeoutSec 10
        Write-Host "  ✅ Flask app is responding!" -ForegroundColor Green
        Write-Host "  Response: $($response.Content)" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Flask app not responding" -ForegroundColor Red
        Write-Host "  Try again in 30 seconds: http://$publicIP/health" -ForegroundColor Yellow
    }

    # Save deployment info
    $deploymentInfo = @{
        InstanceId = $instanceId
        PublicIP = $publicIP
        SecurityGroupId = $sgId
        KeyPairName = $KEY_NAME
        DeployedAt = Get-Date
    }

    $deploymentInfo | ConvertTo-Json | Out-File -FilePath "final-ec2-deployment-$TIMESTAMP.json"

    Write-Host ""
    Write-Host "Final EC2 deployment complete!" -ForegroundColor Green
    Write-Host "Deployment info saved to: final-ec2-deployment-$TIMESTAMP.json" -ForegroundColor Cyan
    Write-Host "To connect via SSH: ssh -i $KEY_NAME.pem ec2-user@$publicIP" -ForegroundColor Yellow
    Write-Host "To terminate instance: aws ec2 terminate-instances --instance-ids $instanceId --region us-east-1" -ForegroundColor Yellow

} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
} 