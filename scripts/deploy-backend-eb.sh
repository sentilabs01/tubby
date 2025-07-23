#!/bin/bash

# AWS Elastic Beanstalk Backend Deployment Script
# This script deploys the Flask backend to AWS Elastic Beanstalk

set -e

echo "🚀 Starting Tubby Backend Deployment to AWS Elastic Beanstalk..."

# Configuration
APP_NAME="tubby-backend"
ENVIRONMENT_NAME="tubby-backend-prod"
REGION="us-east-1"
PLATFORM="Python 3.11"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if EB CLI is installed
if ! command -v eb &> /dev/null; then
    print_warning "EB CLI is not installed. Installing..."
    pip install awsebcli
fi

# Check if we're in the right directory
if [ ! -f "backend/app.py" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

print_status "Creating deployment package..."

# Create deployment directory
DEPLOY_DIR="deploy-backend"
rm -rf $DEPLOY_DIR
mkdir -p $DEPLOY_DIR

# Copy backend files
cp -r backend/* $DEPLOY_DIR/
cp backend/requirements_production.txt $DEPLOY_DIR/requirements.txt

# Create .ebextensions directory and configuration
mkdir -p $DEPLOY_DIR/.ebextensions

# Create environment configuration
cat > $DEPLOY_DIR/.ebextensions/environment.config << EOF
option_settings:
  aws:elasticbeanstalk:application:environment:
    FLASK_ENV: production
    SECRET_KEY: ${SECRET_KEY}
    SUPABASE_URL: https://bemssfbadcfrvzbgjlu.supabase.co
    SUPABASE_ANON_KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlbXNzZmJhZGNmcnZzYmdqbHVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwNDcyOTIsImV4cCI6MjA2ODYyMzI5Mn0.lByWzR-LwRr40IqETUUr0M5dOgUwWE0b_SCuZfLMgyY
    SUPABASE_SERVICE_ROLE_KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlbXNzZmJhZGNmcnZzYmdqbHVhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA0NzI5MiwiZXhwIjoyMDY4NjIzMjkyfQ.Gt_JefY-aTNSrbKKuP-i46Wj8_Blm9HQiZuRd-LUED8
    GOOGLE_CLIENT_ID: 117261848322-rgs0fd2fsk2emdgcd0jhjv4380rcmibh.apps.googleusercontent.com
    GOOGLE_CLIENT_SECRET: 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
    GITHUB_CLIENT_ID: Ov231i0VjZz21dCiQ9oj
    GITHUB_CLIENT_SECRET: 21962b4c088c2d402bb45209c929b58ab93f88ec
    STRIPE_PUBLISHABLE_KEY: pk_live_51RnFitKoB6ANfJLNwqnyzDzOsUMH2Ie6b7SBOvZucOAUFkyPo0PqCsqZmLZq2Kqpzp3qLQa65KQ0jlrLWP3kXSRp00A1NZSjVt
    STRIPE_SECRET_KEY: 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
    STRIPE_BASIC_PRICE_ID: price_1RnI7vKoB6ANfJLNft6upLIC
    STRIPE_PRO_PRICE_ID: price_1RnI8LBKoB6ANfJLNRNUyRVIX
    STRIPE_ENTERPRISE_PRICE_ID: price_1RnI9FKoB6ANfJLNwZTZ5M8A
    BACKEND_URL: https://api.tubbyai.com
    FRONTEND_URL: https://tubbyai.com
EOF

# Create platform configuration
cat > $DEPLOY_DIR/.ebextensions/platform.config << EOF
option_settings:
  aws:elasticbeanstalk:container:python:
    WSGIPath: app_production:app
  aws:elasticbeanstalk:environment:proxy:staticfiles:
    /static: static
EOF

# Create Procfile
cat > $DEPLOY_DIR/Procfile << EOF
web: gunicorn --config gunicorn.conf.py app_production:app
EOF

print_status "Deployment package created in $DEPLOY_DIR"

# Navigate to deployment directory
cd $DEPLOY_DIR

# Initialize EB application if it doesn't exist
if ! eb list &> /dev/null; then
    print_status "Initializing Elastic Beanstalk application..."
    eb init $APP_NAME --platform "$PLATFORM" --region $REGION
fi

# Deploy to environment
print_status "Deploying to Elastic Beanstalk environment: $ENVIRONMENT_NAME"
eb deploy $ENVIRONMENT_NAME

print_status "Deployment completed successfully!"
print_status "Your backend should be available at: https://api.tubbyai.com"

# Clean up
cd ..
rm -rf $DEPLOY_DIR

print_status "Deployment script completed!" 