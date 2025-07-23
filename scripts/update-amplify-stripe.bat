@echo off
echo 🚀 Updating Amplify Environment Variables with Correct Stripe Configuration

REM Set your Amplify App ID and Region
set APP_ID=d34pheadvyr3df
set REGION=us-east-1

echo 🔧 Updating environment variables for app: %APP_ID% in region: %REGION%

REM Update all environment variables with the correct Stripe configuration
aws amplify update-app --app-id %APP_ID% --region %REGION% --cli-input-json file://scripts/amplify-env-updated.json

if %ERRORLEVEL% EQU 0 (
    echo ✅ All environment variables have been updated successfully!
    echo.
    echo 📋 Updated Stripe Configuration:
    echo   - Secret Key: Updated with new valid key
    echo   - Pro Price ID: price_1RnI8LKoB6ANfJLNRNuYrViX ($29.99)
    echo   - Enterprise Price ID: price_1RnI9FKoB6ANfJLNWZTZ5M8A ($99.99)
    echo.
    echo 📋 Next steps:
    echo 1. Redeploy your app in Amplify
    echo 2. Test the payment flow
    echo 3. Verify OAuth authentication
    echo.
    echo 🔗 Amplify Console: https://console.aws.amazon.com/amplify/
) else (
    echo ❌ Failed to update environment variables. Please check the error above.
)

pause 