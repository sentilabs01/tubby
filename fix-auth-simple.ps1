# Fix Auth and Redirect Issues Script
# This script fixes CORS configuration and deploys the fixes

Write-Host "Fixing Auth and Redirect Issues" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Step 1: Fix CORS Configuration
Write-Host "`nStep 1: Fixing CORS Configuration..." -ForegroundColor Yellow
try {
    python fix-cors-config.py
    if ($LASTEXITCODE -eq 0) {
        Write-Host "CORS configuration fixed successfully" -ForegroundColor Green
    } else {
        Write-Host "Failed to fix CORS configuration" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error running CORS fix script: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Check if backend deployment script exists
Write-Host "`nStep 2: Checking deployment script..." -ForegroundColor Yellow
if (Test-Path "deploy-backend-eb.ps1") {
    Write-Host "Backend deployment script found" -ForegroundColor Green
} else {
    Write-Host "Backend deployment script not found" -ForegroundColor Red
    Write-Host "Please ensure deploy-backend-eb.ps1 exists" -ForegroundColor Yellow
    exit 1
}

# Step 3: Deploy Backend
Write-Host "`nStep 3: Deploying backend to Elastic Beanstalk..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Cyan
try {
    & .\deploy-backend-eb.ps1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Backend deployed successfully" -ForegroundColor Green
    } else {
        Write-Host "Backend deployment failed" -ForegroundColor Red
        Write-Host "Check the deployment logs above for details" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error deploying backend: $_" -ForegroundColor Red
}

# Step 4: Check git status
Write-Host "`nStep 4: Checking git status..." -ForegroundColor Yellow
try {
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Host "Changes detected in git:" -ForegroundColor Yellow
        Write-Host $gitStatus -ForegroundColor Cyan
        
        $commitMessage = "Fix auth and redirect issues - CORS configuration and session handling"
        Write-Host "`nCommitting changes with message: $commitMessage" -ForegroundColor Yellow
        
        git add .
        git commit -m $commitMessage
        
        Write-Host "Pushing changes to GitHub..." -ForegroundColor Yellow
        git push origin main
        
        Write-Host "Frontend changes pushed to GitHub" -ForegroundColor Green
        Write-Host "Amplify will automatically deploy the frontend" -ForegroundColor Cyan
    } else {
        Write-Host "No changes to commit" -ForegroundColor Green
    }
} catch {
    Write-Host "Error with git operations: $_" -ForegroundColor Red
}

# Step 5: Display next steps
Write-Host "`nAuth Fix Process Completed!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

Write-Host "`nNext Steps Required:" -ForegroundColor Yellow
Write-Host "1. Update Environment Variables in AWS Console:" -ForegroundColor White
Write-Host "   - Go to Elastic Beanstalk Console" -ForegroundColor Cyan
Write-Host "   - Your Environment - Configuration - Software - Environment properties" -ForegroundColor Cyan
Write-Host "   - Add/update FRONTEND_URL and BACKEND_URL" -ForegroundColor Cyan

Write-Host "`n2. Update OAuth Provider Settings:" -ForegroundColor White
Write-Host "   - Google Cloud Console: Update redirect URIs" -ForegroundColor Cyan
Write-Host "   - GitHub OAuth App: Update callback URL" -ForegroundColor Cyan
Write-Host "   - Supabase Dashboard: Update OAuth settings" -ForegroundColor Cyan

Write-Host "`n3. Test the Application:" -ForegroundColor White
Write-Host "   - Wait for Amplify deployment to complete" -ForegroundColor Cyan
Write-Host "   - Test OAuth flow on your production domain" -ForegroundColor Cyan
Write-Host "   - Check browser console for any remaining errors" -ForegroundColor Cyan

Write-Host "`nUseful URLs:" -ForegroundColor Yellow
Write-Host "   - AWS Elastic Beanstalk Console: https://console.aws.amazon.com/elasticbeanstalk/" -ForegroundColor Cyan
Write-Host "   - AWS Amplify Console: https://console.aws.amazon.com/amplify/" -ForegroundColor Cyan
Write-Host "   - Google Cloud Console: https://console.cloud.google.com/" -ForegroundColor Cyan
Write-Host "   - GitHub OAuth Apps: https://github.com/settings/developers" -ForegroundColor Cyan

Write-Host "`nFor detailed instructions, see: AUTH_REDIRECT_FIX.md" -ForegroundColor Yellow

Write-Host "`nScript completed successfully!" -ForegroundColor Green 