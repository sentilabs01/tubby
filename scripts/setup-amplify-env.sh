#!/bin/bash

# Amplify Environment Variables Setup Script
# This script helps you set environment variables in AWS Amplify

echo "🚀 Setting up Amplify Environment Variables for Tubby AI"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check if user is logged in
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ You are not logged in to AWS CLI. Please run 'aws configure' first."
    exit 1
fi

# Get app ID from user
echo "📝 Please enter your Amplify App ID:"
read -p "App ID: " APP_ID

# Get branch name (usually main)
echo "📝 Please enter your branch name (default: main):"
read -p "Branch: " BRANCH
BRANCH=${BRANCH:-main}

echo "🔧 Setting up environment variables for app: $APP_ID, branch: $BRANCH"

# Function to set environment variable
set_env_var() {
    local key=$1
    local value=$2
    echo "Setting $key..."
    aws amplify update-app --app-id $APP_ID --environment-variables "$key=$value"
}

# Frontend Variables
set_env_var "VITE_API_URL" "https://tubbyai.com"

# Backend Variables
set_env_var "FLASK_ENV" "production"
set_env_var "SECRET_KEY" "your-secure-secret-key-here"
set_env_var "SUPABASE_URL" "your-supabase-url"
set_env_var "SUPABASE_ANON_KEY" "your-supabase-anon-key"
set_env_var "SUPABASE_SERVICE_ROLE_KEY" "your-supabase-service-role-key"
set_env_var "GOOGLE_CLIENT_ID" "117261848322-rgs0fd2fsk2emdgcd0jhjv4380rcmibh.apps.googleusercontent.com"
set_env_var "GOOGLE_CLIENT_SECRET" "your-google-client-secret"
set_env_var "GITHUB_CLIENT_ID" "Ov23li0VjZz21dCiQ9oj"
set_env_var "GITHUB_CLIENT_SECRET" "your-github-client-secret"
set_env_var "STRIPE_PUBLISHABLE_KEY" "your-stripe-publishable-key"
set_env_var "STRIPE_SECRET_KEY" "your-stripe-secret-key"
set_env_var "STRIPE_WEBHOOK_SECRET" "your-stripe-webhook-secret"
set_env_var "REDIS_HOST" "your-redis-host"
set_env_var "REDIS_PORT" "6379"
set_env_var "ALLOWED_ORIGINS" "https://tubbyai.com,http://localhost:3001"
set_env_var "BACKEND_URL" "https://api.tubbyai.com"
set_env_var "FRONTEND_URL" "https://tubbyai.com"

echo "✅ Environment variables have been set!"
echo ""
echo "📋 Next steps:"
echo "1. Update the placeholder values with your actual credentials"
echo "2. Redeploy your app in the Amplify console"
echo "3. Test the OAuth authentication flow"
echo ""
echo "🔗 Amplify Console: https://console.aws.amazon.com/amplify/" 