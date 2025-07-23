# Clean Secrets from Documentation Script
# This script replaces actual secrets with placeholders in documentation files

Write-Host "Cleaning Secrets from Documentation" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# List of files to clean
$filesToClean = @(
    "AWS_BACKEND_DEPLOYMENT_GUIDE.md",
    "CONFIGURATION_REFERENCE.md",
    "LOCAL_DEV_SETUP.md",
    "STRIPE_CHECKOUT_FIX.md",
    "backend/.ebextensions/environment.config",
    "scripts/deploy-backend-eb.sh"
)

foreach ($file in $filesToClean) {
    if (Test-Path $file) {
        Write-Host "Cleaning: $file" -ForegroundColor Yellow
        
        # Read file content
        $content = Get-Content $file -Raw -Encoding UTF8
        
        # Replace secrets with placeholders
        $content = $content -replace 'sk_live_[a-zA-Z0-9]{24}', 'sk_live_your-stripe-secret-key'
        $content = $content -replace 'pk_live_[a-zA-Z0-9]{24}', 'pk_live_your-stripe-publishable-key'
        $content = $content -replace 'sk_test_[a-zA-Z0-9]{24}', 'sk_test_your-stripe-secret-key'
        $content = $content -replace 'pk_test_[a-zA-Z0-9]{24}', 'pk_test_your-stripe-publishable-key'
        $content = $content -replace '[0-9]+-[a-zA-Z0-9]{32}\.apps\.googleusercontent\.com', 'your-google-client-id.apps.googleusercontent.com'
        $content = $content -replace 'GOCSPX-[a-zA-Z0-9_-]+', 'your-google-client-secret'
        $content = $content -replace 'Ov23[a-zA-Z0-9]+', 'your-github-client-id'
        $content = $content -replace '21962[a-zA-Z0-9]+', 'your-github-client-secret'
        $content = $content -replace 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+', 'your-supabase-anon-key'
        
        # Write cleaned content back
        Set-Content $file -Value $content -Encoding UTF8
        Write-Host "✅ Cleaned: $file" -ForegroundColor Green
    } else {
        Write-Host "⚠️ File not found: $file" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ All documentation files cleaned!" -ForegroundColor Green
Write-Host "Secrets have been replaced with placeholders." -ForegroundColor Cyan 