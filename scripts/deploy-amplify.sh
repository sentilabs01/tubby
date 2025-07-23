#!/bin/bash

# Amplify Deployment Script for Tubby AI
# This script helps prepare and deploy the application to AWS Amplify

set -e

echo "🚀 Starting Tubby AI Amplify Deployment..."

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

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -f "amplify.yml" ]; then
    print_error "This script must be run from the project root directory"
    exit 1
fi

# Step 1: Check environment variables
print_status "Checking environment variables..."
if [ ! -f ".env" ]; then
    print_warning "No .env file found. Please create one from env.example"
    print_status "Copying env.example to .env..."
    cp env.example .env
    print_warning "Please edit .env with your actual values before deploying"
fi

# Step 2: Install dependencies
print_status "Installing frontend dependencies..."
npm ci

print_status "Installing backend dependencies..."
cd backend
pip install -r requirements_production.txt
cd ..

# Step 3: Build frontend
print_status "Building frontend application..."
npm run build

# Step 4: Test backend
print_status "Testing backend health..."
cd backend
python -c "
import os
import sys
sys.path.append('.')
from app_production import app
with app.test_client() as client:
    response = client.get('/health')
    if response.status_code == 200:
        print('✅ Backend health check passed')
    else:
        print('❌ Backend health check failed')
        sys.exit(1)
"
cd ..

# Step 5: Check for required files
print_status "Checking required files for deployment..."

required_files=(
    "amplify.yml"
    "package.json"
    "vite.config.js"
    "backend/requirements_production.txt"
    "backend/start_production.py"
    "backend/app_production.py"
    "dist/index.html"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_status "✅ $file found"
    else
        print_error "❌ $file not found"
        exit 1
    fi
done

# Step 6: Git status check
print_status "Checking Git status..."
if [ -n "$(git status --porcelain)" ]; then
    print_warning "You have uncommitted changes. Consider committing them before deployment."
    git status --short
else
    print_status "✅ Working directory is clean"
fi

# Step 7: Deployment instructions
echo ""
print_status "🎉 Preparation complete! Ready for Amplify deployment."
echo ""
echo "Next steps:"
echo "1. Push your changes to GitHub:"
echo "   git add ."
echo "   git commit -m 'Prepare for Amplify deployment'"
echo "   git push origin main"
echo ""
echo "2. In AWS Amplify Console:"
echo "   - Connect your GitHub repository"
echo "   - Configure environment variables"
echo "   - Deploy the application"
echo ""
echo "3. Set up external services:"
echo "   - Redis instance (ElastiCache recommended)"
echo "   - Supabase production database"
echo "   - OAuth redirect URLs"
echo ""
echo "For detailed instructions, see: AMPLIFY_DEPLOYMENT_GUIDE.md"

print_status "Deployment preparation completed successfully! 🚀" 