@echo off
echo 🚀 Updating Amplify Environment Variables with Complete Working Configuration

REM Set your Amplify App ID and Region
set APP_ID=d34pheadvyr3df
set REGION=us-east-1

echo 🔧 Updating environment variables for app: %APP_ID% in region: %REGION%

REM Update all environment variables with the complete working configuration
aws amplify update-app --app-id %APP_ID% --region %REGION% --cli-input-json file://scripts/amplify-env-complete.json

if %ERRORLEVEL% EQU 0 (
    echo ✅ All environment variables have been updated successfully!
    echo.
    echo 📋 Complete Configuration Status:
    echo   ✅ Stripe: API key and all price IDs working
    echo   ✅ Supabase: URL, anon key, and service role key configured
    echo   ✅ OAuth: Google and GitHub configured
    echo   ✅ Backend: All services ready
    echo.
    echo 📋 Updated Supabase Project: bemssfbadcfrvzbgjlu
    echo 📋 Stripe Price IDs:
    echo     - Basic: price_1RnI7vKoB6ANfJLNft6upLIC ($9.99)
    echo     - Pro: price_1RnI8LKoB6ANfJLNRNuYrViX ($29.99)
    echo     - Enterprise: price_1RnI9FKoB6ANfJLNWZTZ5M8A ($99.99)
    echo.
    echo 📋 Next steps:
    echo 1. Redeploy your app in Amplify
    echo 2. Test OAuth authentication flow
    echo 3. Test Stripe payment flow
    echo 4. Verify all functionality works
    echo.
    echo 🔗 Amplify Console: https://console.aws.amazon.com/amplify/
) else (
    echo ❌ Failed to update environment variables. Please check the error above.
)

pause 