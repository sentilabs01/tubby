@echo off
echo 🚀 Setting up ALL Amplify Environment Variables for Tubby AI

REM Set your Amplify App ID and Region
set APP_ID=d34pheadvyr3df
set REGION=us-east-1

echo 🔧 Setting up environment variables for app: %APP_ID% in region: %REGION%

REM Set all environment variables at once using the JSON file
aws amplify update-app --app-id %APP_ID% --region %REGION% --cli-input-json file://scripts/amplify-env.json

if %ERRORLEVEL% EQU 0 (
    echo ✅ All environment variables have been set successfully!
    echo.
    echo 📋 Next steps:
    echo 1. Check the Amplify console to verify all variables are set
    echo 2. Redeploy your app
    echo 3. Test the OAuth authentication flow
    echo.
    echo 🔗 Amplify Console: https://console.aws.amazon.com/amplify/
) else (
    echo ❌ Failed to set environment variables. Please check the error above.
)

pause 