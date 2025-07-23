# AWS Deployment Script for Tubby AI
# This script deploys your frontend to AWS S3 and optionally sets up CloudFront

param(
    [string]$BucketName = "tubby-ai-frontend",
    [string]$Region = "us-east-1",
    [switch]$CreateBucket,
    [switch]$SetupCloudFront
)

Write-Host "🚀 Tubby AI AWS Deployment" -ForegroundColor Blue

# Check if AWS CLI is installed
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "❌ AWS CLI not found. Please install it first." -ForegroundColor Red
    Write-Host "Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check AWS credentials
Write-Host "🔑 Checking AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
    if ($identity) {
        Write-Host "✅ AWS credentials found for: $($identity.Arn)" -ForegroundColor Green
    } else {
        Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
        Write-Host "Run: aws configure" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
    Write-Host "Run: aws configure" -ForegroundColor Yellow
    exit 1
}

# Build frontend
Write-Host "🔨 Building frontend..." -ForegroundColor Yellow
npm run build:prod
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Frontend build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Frontend build successful" -ForegroundColor Green

# Create S3 bucket if requested
if ($CreateBucket) {
    Write-Host "🪣 Creating S3 bucket: $BucketName" -ForegroundColor Yellow
    try {
        aws s3 mb "s3://$BucketName" --region $Region
        Write-Host "✅ S3 bucket created" -ForegroundColor Green
        
        # Configure for static website hosting
        Write-Host "🌐 Configuring static website hosting..." -ForegroundColor Yellow
        aws s3 website "s3://$BucketName" --index-document index.html --error-document index.html
        
        # Create bucket policy for public read access
        $bucketPolicy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BucketName/*"
        }
    ]
}
"@
        
        $bucketPolicy | Out-File -FilePath "bucket-policy.json" -Encoding UTF8
        aws s3api put-bucket-policy --bucket $BucketName --policy file://bucket-policy.json
        Remove-Item "bucket-policy.json"
        
        Write-Host "✅ Bucket configured for public access" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create bucket: $_" -ForegroundColor Red
        exit 1
    }
}

# Check if bucket exists
Write-Host "🔍 Checking if bucket exists..." -ForegroundColor Yellow
$bucketExists = aws s3 ls "s3://$BucketName" 2>$null
if (-not $bucketExists) {
    Write-Host "❌ Bucket '$BucketName' does not exist" -ForegroundColor Red
    Write-Host "Use -CreateBucket flag to create it" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Bucket found" -ForegroundColor Green

# Upload frontend files
Write-Host "📁 Uploading frontend files..." -ForegroundColor Yellow
try {
    aws s3 sync dist/ "s3://$BucketName" --delete
    Write-Host "✅ Frontend uploaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Upload failed: $_" -ForegroundColor Red
    exit 1
}

# Get website URL
$websiteUrl = aws s3api get-bucket-website --bucket $BucketName --query 'WebsiteEndpoint' --output text 2>$null
if ($websiteUrl) {
    Write-Host "🌐 Website URL: http://$websiteUrl" -ForegroundColor Green
} else {
    Write-Host "🌐 Files uploaded to: s3://$BucketName" -ForegroundColor Green
}

# Setup CloudFront if requested
if ($SetupCloudFront) {
    Write-Host "☁️ Setting up CloudFront distribution..." -ForegroundColor Yellow
    Write-Host "⚠️ CloudFront setup requires manual configuration in AWS Console" -ForegroundColor Yellow
    Write-Host "1. Go to CloudFront in AWS Console" -ForegroundColor White
    Write-Host "2. Create distribution" -ForegroundColor White
    Write-Host "3. Set origin to: $BucketName.s3.amazonaws.com" -ForegroundColor White
    Write-Host "4. Set default root object to: index.html" -ForegroundColor White
}

Write-Host "`n🎉 Deployment completed!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure your domain (if you have one)" -ForegroundColor White
Write-Host "2. Set up CloudFront for HTTPS and CDN" -ForegroundColor White
Write-Host "3. Deploy your backend to AWS (EC2, Lambda, etc.)" -ForegroundColor White
Write-Host "4. Test the application" -ForegroundColor White

if ($websiteUrl) {
    Write-Host "`n🔗 Your app is live at: http://$websiteUrl" -ForegroundColor Cyan
} 