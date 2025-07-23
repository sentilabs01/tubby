#!/bin/bash

# Tubby AI Server Upload Script
# Customize the variables below for your server

# Server Configuration
SERVER_USER="your-username"
SERVER_HOST="your-server.com"
SERVER_KEY="~/.ssh/your-key.pem"  # Optional: path to SSH key

# Directory Configuration
FRONTEND_DIR="/var/www/tubby"
BACKEND_DIR="/opt/tubby-backend"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Tubby AI Server Upload${NC}"

# Check if dist folder exists
if [ ! -d "dist" ]; then
    echo -e "${RED}❌ dist folder not found. Run 'npm run build:prod' first.${NC}"
    exit 1
fi

# Check if backend folder exists
if [ ! -d "backend" ]; then
    echo -e "${RED}❌ backend folder not found.${NC}"
    exit 1
fi

# Build frontend if not already built
echo -e "${YELLOW}🔨 Building frontend...${NC}"
npm run build:prod

# Upload frontend files
echo -e "${YELLOW}📁 Uploading frontend files...${NC}"
if [ -f "$SERVER_KEY" ]; then
    scp -i "$SERVER_KEY" -r dist/* "$SERVER_USER@$SERVER_HOST:$FRONTEND_DIR/"
else
    scp -r dist/* "$SERVER_USER@$SERVER_HOST:$FRONTEND_DIR/"
fi

# Upload backend files
echo -e "${YELLOW}📁 Uploading backend files...${NC}"
if [ -f "$SERVER_KEY" ]; then
    scp -i "$SERVER_KEY" -r backend/* "$SERVER_USER@$SERVER_HOST:$BACKEND_DIR/"
else
    scp -r backend/* "$SERVER_USER@$SERVER_HOST:$BACKEND_DIR/"
fi

# Upload configuration files
echo -e "${YELLOW}📁 Uploading configuration files...${NC}"
if [ -f "$SERVER_KEY" ]; then
    scp -i "$SERVER_KEY" package.json vite.config.js amplify.yml env.example "$SERVER_USER@$SERVER_HOST:$BACKEND_DIR/"
else
    scp package.json vite.config.js amplify.yml env.example "$SERVER_USER@$SERVER_HOST:$BACKEND_DIR/"
fi

echo -e "${GREEN}✅ Upload completed!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "1. SSH into your server: ssh $SERVER_USER@$SERVER_HOST"
echo -e "2. Set up environment variables: nano $BACKEND_DIR/.env"
echo -e "3. Install backend dependencies: cd $BACKEND_DIR && pip install -r requirements_production.txt"
echo -e "4. Start the backend: python start_production.py"
echo -e "5. Configure web server (nginx/apache)"
echo -e "6. Test the application" 