# Tubby AI Server Upload Script (PowerShell)
# Customize the variables below for your server

# Server Configuration
$ServerUser = "your-username"
$ServerHost = "your-server.com"
$ServerKey = "~/.ssh/your-key.pem"  # Optional: path to SSH key

# Directory Configuration
$FrontendDir = "/var/www/tubby"
$BackendDir = "/opt/tubby-backend"

Write-Host "🚀 Tubby AI Server Upload" -ForegroundColor Green

# Check if dist folder exists
if (-not (Test-Path "dist")) {
    Write-Host "❌ dist folder not found. Run 'npm run build:prod' first." -ForegroundColor Red
    exit 1
}

# Check if backend folder exists
if (-not (Test-Path "backend")) {
    Write-Host "❌ backend folder not found." -ForegroundColor Red
    exit 1
}

# Build frontend if not already built
Write-Host "🔨 Building frontend..." -ForegroundColor Yellow
npm run build:prod

# Upload frontend files
Write-Host "📁 Uploading frontend files..." -ForegroundColor Yellow
if (Test-Path $ServerKey) {
    scp -i $ServerKey -r dist/* "$ServerUser@$ServerHost`:$FrontendDir/"
} else {
    scp -r dist/* "$ServerUser@$ServerHost`:$FrontendDir/"
}

# Upload backend files
Write-Host "📁 Uploading backend files..." -ForegroundColor Yellow
if (Test-Path $ServerKey) {
    scp -i $ServerKey -r backend/* "$ServerUser@$ServerHost`:$BackendDir/"
} else {
    scp -r backend/* "$ServerUser@$ServerHost`:$BackendDir/"
}

# Upload configuration files
Write-Host "📁 Uploading configuration files..." -ForegroundColor Yellow
if (Test-Path $ServerKey) {
    scp -i $ServerKey package.json vite.config.js amplify.yml env.example "$ServerUser@$ServerHost`:$BackendDir/"
} else {
    scp package.json vite.config.js amplify.yml env.example "$ServerUser@$ServerHost`:$BackendDir/"
}

Write-Host "✅ Upload completed!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. SSH into your server: ssh $ServerUser@$ServerHost" -ForegroundColor White
Write-Host "2. Set up environment variables: nano $BackendDir/.env" -ForegroundColor White
Write-Host "3. Install backend dependencies: cd $BackendDir && pip install -r requirements_production.txt" -ForegroundColor White
Write-Host "4. Start the backend: python start_production.py" -ForegroundColor White
Write-Host "5. Configure web server (nginx/apache)" -ForegroundColor White
Write-Host "6. Test the application" -ForegroundColor White 