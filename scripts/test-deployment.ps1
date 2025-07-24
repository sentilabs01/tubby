# Systematic Deployment Testing for TubbyAI
param(
    [string]$InstanceId = "i-09e38a5e580ed6202"
)

Write-Host "TubbyAI Deployment Testing" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

# Get instance info
Write-Host "1. Checking EC2 Instance Status..." -ForegroundColor Yellow
$instanceInfo = aws ec2 describe-instances --instance-ids $InstanceId --region us-east-1 --query 'Reservations[0].Instances[0]' --output json | ConvertFrom-Json

Write-Host "   Instance ID: $($instanceInfo.InstanceId)" -ForegroundColor Cyan
Write-Host "   State: $($instanceInfo.State.Name)" -ForegroundColor Cyan
Write-Host "   Public IP: $($instanceInfo.PublicIpAddress)" -ForegroundColor Cyan
Write-Host "   Instance Type: $($instanceInfo.InstanceType)" -ForegroundColor Cyan

# Check security groups
Write-Host "2. Checking Security Groups..." -ForegroundColor Yellow
$sgId = $instanceInfo.SecurityGroups[0].GroupId
$sgRules = aws ec2 describe-security-groups --group-ids $sgId --region us-east-1 --query 'SecurityGroups[0].IpPermissions' --output json | ConvertFrom-Json

Write-Host "   Security Group: $sgId" -ForegroundColor Cyan
foreach ($rule in $sgRules) {
    Write-Host "   Port $($rule.FromPort)-$($rule.ToPort) ($($rule.IpProtocol)): $($rule.IpRanges[0].CidrIp)" -ForegroundColor Cyan
}

# Test network connectivity
Write-Host "3. Testing Network Connectivity..." -ForegroundColor Yellow
$publicIP = $instanceInfo.PublicIpAddress

# Test ping
Write-Host "   Testing ping..." -ForegroundColor Cyan
try {
    $ping = Test-Connection -ComputerName $publicIP -Count 1 -Quiet
    if ($ping) {
        Write-Host "   ✅ Ping successful" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Ping failed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Ping failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test port 22 (SSH)
Write-Host "   Testing SSH (port 22)..." -ForegroundColor Cyan
try {
    $sshTest = Test-NetConnection -ComputerName $publicIP -Port 22 -InformationLevel Quiet
    if ($sshTest.TcpTestSucceeded) {
        Write-Host "   ✅ SSH port open" -ForegroundColor Green
    } else {
        Write-Host "   ❌ SSH port closed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ SSH test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test port 80 (HTTP)
Write-Host "   Testing HTTP (port 80)..." -ForegroundColor Cyan
try {
    $httpTest = Test-NetConnection -ComputerName $publicIP -Port 80 -InformationLevel Quiet
    if ($httpTest.TcpTestSucceeded) {
        Write-Host "   ✅ HTTP port open" -ForegroundColor Green
    } else {
        Write-Host "   ❌ HTTP port closed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ HTTP test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test web application
Write-Host "4. Testing Web Application..." -ForegroundColor Yellow

# Test nginx static page
Write-Host "   Testing nginx static page..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://$publicIP" -TimeoutSec 10 -UseBasicParsing
    Write-Host "   ✅ Nginx responding (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "   Content: $($response.Content.Trim())" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Nginx not responding: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Flask health endpoint
Write-Host "   Testing Flask health endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://$publicIP/health" -TimeoutSec 10 -UseBasicParsing
    Write-Host "   ✅ Flask app responding (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "   Content: $($response.Content.Trim())" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Flask app not responding: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Flask test endpoint
Write-Host "   Testing Flask test endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://$publicIP/test" -TimeoutSec 10 -UseBasicParsing
    Write-Host "   ✅ Flask test endpoint responding (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "   Content: $($response.Content.Trim())" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Flask test endpoint not responding: $($_.Exception.Message)" -ForegroundColor Red
}

# Check if we can SSH (if key exists)
Write-Host "5. Testing SSH Access..." -ForegroundColor Yellow
$keyFiles = Get-ChildItem *.pem | Sort-Object LastWriteTime -Descending
if ($keyFiles) {
    $latestKey = $keyFiles[0].Name
    Write-Host "   Found key: $latestKey" -ForegroundColor Cyan
    
    # Test SSH connection
    Write-Host "   Testing SSH connection..." -ForegroundColor Cyan
    try {
        $sshResult = ssh -i $latestKey -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes ec2-user@$publicIP "echo 'SSH connection successful'" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ SSH connection successful" -ForegroundColor Green
        } else {
            Write-Host "   ❌ SSH connection failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ❌ SSH test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ No SSH key found" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "Testing Summary:" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green
Write-Host "Instance: $InstanceId" -ForegroundColor Cyan
Write-Host "Public IP: $publicIP" -ForegroundColor Cyan
Write-Host "URL: http://$publicIP" -ForegroundColor Cyan
Write-Host "Health: http://$publicIP/health" -ForegroundColor Cyan

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. If nginx works but Flask doesn't: Check Flask app logs" -ForegroundColor White
Write-Host "2. If nothing works: Check user data script execution" -ForegroundColor White
Write-Host "3. If SSH works: Connect and debug manually" -ForegroundColor White
Write-Host "4. If all fails: Try a different deployment approach" -ForegroundColor White 