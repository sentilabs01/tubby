#!/bin/bash

# Tubby AI Production Deployment Script
# This script handles both frontend and backend deployment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_DIR="."
BACKEND_DIR="backend"
PROJECT_NAME="tubby-ai"
VERSION=$(date +%Y%m%d-%H%M%S)

echo -e "${BLUE}🚀 Starting Tubby AI Production Deployment v${VERSION}${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        print_error "git is not installed"
        exit 1
    fi
    
    print_status "All dependencies found"
}

# Build frontend
build_frontend() {
    print_status "Building frontend..."
    
    cd "$FRONTEND_DIR"
    
    # Clean previous build
    if [ -d "dist" ]; then
        rm -rf dist
        print_status "Cleaned previous build"
    fi
    
    # Install dependencies
    print_status "Installing frontend dependencies..."
    npm ci --production=false
    
    # Build for production
    print_status "Building for production..."
    npm run build:prod
    
    # Verify build
    if [ ! -d "dist" ]; then
        print_error "Frontend build failed - dist directory not found"
        exit 1
    fi
    
    print_status "Frontend built successfully"
    cd ..
}

# Build backend
build_backend() {
    print_status "Building backend..."
    
    cd "$BACKEND_DIR"
    
    # Check if requirements files exist
    if [ ! -f "requirements_production.txt" ]; then
        print_error "Backend requirements file not found"
        exit 1
    fi
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install dependencies
    print_status "Installing backend dependencies..."
    pip install -r requirements_production.txt
    
    # Test backend
    print_status "Testing backend..."
    python -c "import flask; print('Flask imported successfully')"
    
    deactivate
    cd ..
    
    print_status "Backend prepared successfully"
}

# Deploy to AWS Amplify (Frontend)
deploy_frontend_amplify() {
    print_status "Deploying frontend to AWS Amplify..."
    
    # Check if Amplify CLI is installed
    if ! command -v amplify &> /dev/null; then
        print_warning "Amplify CLI not found. Installing..."
        npm install -g @aws-amplify/cli
    fi
    
    # Check if project is initialized
    if [ ! -f "amplify/.config/local-env-info.json" ]; then
        print_warning "Amplify project not initialized. Please run: amplify init"
        print_warning "Skipping Amplify deployment"
        return
    fi
    
    # Deploy to Amplify
    amplify publish --yes
    
    print_status "Frontend deployed to Amplify"
}

# Deploy to AWS Elastic Beanstalk (Backend)
deploy_backend_eb() {
    print_status "Deploying backend to AWS Elastic Beanstalk..."
    
    cd "$BACKEND_DIR"
    
    # Check if EB CLI is installed
    if ! command -v eb &> /dev/null; then
        print_warning "EB CLI not found. Installing..."
        pip install awsebcli
    fi
    
    # Check if EB project is initialized
    if [ ! -f ".elasticbeanstalk/config.yml" ]; then
        print_warning "EB project not initialized. Please run: eb init"
        print_warning "Skipping EB deployment"
        cd ..
        return
    fi
    
    # Deploy to EB
    eb deploy --timeout 20
    
    cd ..
    
    print_status "Backend deployed to Elastic Beanstalk"
}

# Create deployment package
create_deployment_package() {
    print_status "Creating deployment package..."
    
    PACKAGE_NAME="${PROJECT_NAME}-${VERSION}.tar.gz"
    
    # Create package directory
    mkdir -p "deployment-package"
    
    # Copy frontend build
    cp -r dist/* deployment-package/
    
    # Copy backend files
    mkdir -p deployment-package/backend
    cp -r backend/* deployment-package/backend/
    
    # Copy configuration files
    cp package.json deployment-package/
    cp vite.config.js deployment-package/
    cp amplify.yml deployment-package/
    
    # Create deployment info
    cat > deployment-package/DEPLOYMENT_INFO.txt << EOF
Tubby AI Deployment Package
Version: ${VERSION}
Build Time: $(date)
Environment: Production
Frontend: Built with Vite
Backend: Flask with Gunicorn
EOF
    
    # Create tar.gz package
    tar -czf "$PACKAGE_NAME" deployment-package/
    
    # Clean up
    rm -rf deployment-package/
    
    print_status "Deployment package created: $PACKAGE_NAME"
}

# Health check
health_check() {
    print_status "Performing health checks..."
    
    # Frontend health check
    if [ -d "dist" ]; then
        if [ -f "dist/index.html" ]; then
            print_status "Frontend build verified"
        else
            print_error "Frontend build incomplete"
            return 1
        fi
    else
        print_error "Frontend build not found"
        return 1
    fi
    
    # Backend health check
    if [ -f "backend/app.py" ]; then
        print_status "Backend files verified"
    else
        print_error "Backend files not found"
        return 1
    fi
    
    print_status "All health checks passed"
}

# Main deployment flow
main() {
    echo -e "${BLUE}Starting deployment process...${NC}"
    
    # Check dependencies
    check_dependencies
    
    # Build applications
    build_frontend
    build_backend
    
    # Health checks
    health_check
    
    # Create deployment package
    create_deployment_package
    
    # Deploy (optional - uncomment if you want automatic deployment)
    # deploy_frontend_amplify
    # deploy_backend_eb
    
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "${BLUE}Deployment package: ${PROJECT_NAME}-${VERSION}.tar.gz${NC}"
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Upload the deployment package to your hosting provider"
    echo -e "  2. Configure environment variables"
    echo -e "  3. Start the application"
    echo -e "  4. Run health checks"
}

# Run main function
main "$@" 