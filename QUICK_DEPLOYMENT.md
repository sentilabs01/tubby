# Quick Deployment Guide for Tubby AI

## 🚀 Production-Ready Deployment

Your Tubby AI application is now production-ready! Here's how to deploy it:

## ✅ What's Ready

### Frontend (React + Vite)
- ✅ Production build optimized
- ✅ Code splitting enabled
- ✅ Minification and compression
- ✅ Offline mode support
- ✅ Health check component
- ✅ Responsive design

### Backend (Flask + Gunicorn)
- ✅ Production server configuration
- ✅ Eventlet worker class for WebSockets
- ✅ Health checks and monitoring
- ✅ Environment variable handling
- ✅ Security configurations

### Offline Mode
- ✅ Automatic backend detection
- ✅ Graceful degradation
- ✅ Local storage fallback
- ✅ Manual enable/disable controls

## 📦 Manual Deployment Steps

### 1. Build the Frontend
```bash
npm run build:prod
```

This creates a `dist/` folder with optimized files:
- `index.html` - Main entry point
- `assets/` - Optimized CSS and JS files
- Code splitting for better performance

### 2. Prepare Backend
```bash
cd backend
pip install -r requirements_production.txt
```

### 3. Create Deployment Package

**Option A: Manual ZIP**
1. Create a new folder called `deployment`
2. Copy `dist/*` to `deployment/`
3. Copy `backend/` to `deployment/backend/`
4. Copy these files to `deployment/`:
   - `package.json`
   - `vite.config.js`
   - `amplify.yml`
   - `env.example`
5. ZIP the `deployment` folder

**Option B: Use 7-Zip**
```bash
# Install 7-Zip if not available
# Then run:
7z a -tzip tubby-ai-deployment.zip dist/* backend/* package.json vite.config.js amplify.yml env.example
```

### 4. Deploy to Your Server

#### Frontend Deployment
Upload the contents of `dist/` to your web server:
- **Nginx**: Copy to `/var/www/tubby/`
- **Apache**: Copy to `/var/www/html/tubby/`
- **AWS S3**: Upload to S3 bucket
- **Vercel/Netlify**: Drag and drop `dist/` folder

#### Backend Deployment
Upload the `backend/` folder to your server:
- **VPS**: Copy to `/opt/tubby-backend/`
- **AWS EC2**: Copy to `/home/ubuntu/tubby-backend/`
- **AWS Elastic Beanstalk**: Use EB CLI

### 5. Configure Environment Variables

Create `.env` file in the backend directory:

```env
# Flask Configuration
FLASK_ENV=production
SECRET_KEY=your-secret-key-here
PORT=5004
HOST=0.0.0.0

# Supabase Configuration
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# OAuth Configuration
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_WEBHOOK_SECRET=your-stripe-webhook-secret
STRIPE_BASIC_PRICE_ID=price_1RnI7vKoB6ANfJLNft6upLIC
STRIPE_PRO_PRICE_ID=price_1RnI8LBKoB6ANfJLNRNUyRVIX
STRIPE_ENTERPRISE_PRICE_ID=price_1RnI9FKoB6ANfJLNwZTZ5M8A

# CORS Configuration
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Backend URL (for OAuth callbacks)
BACKEND_URL=https://api.yourdomain.com
```

### 6. Start the Backend

```bash
cd backend
python start_production.py
```

Or use Gunicorn directly:
```bash
cd backend
gunicorn --config gunicorn.conf.py app:app
```

### 7. Configure Web Server

#### Nginx Configuration
```nginx
server {
    listen 80;
    server_name yourdomain.com;
    
    # Frontend
    location / {
        root /var/www/tubby;
        try_files $uri $uri/ /index.html;
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:5004;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket support
    location /socket.io {
        proxy_pass http://localhost:5004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

## 🔍 Health Checks

### Frontend Health Check
```bash
curl https://yourdomain.com/
# Should return the main HTML page
```

### Backend Health Check
```bash
curl https://yourdomain.com/api/health
# Should return: {"status": "healthy", "timestamp": "..."}
```

## 🛡️ Offline Mode

The application includes automatic offline mode:

1. **Auto-detection**: Checks backend health every 30 seconds
2. **Graceful degradation**: Blocks backend calls when unavailable
3. **Local storage**: Uses cached user data
4. **Manual control**: Can be enabled/disabled via UI

**Enable offline mode manually:**
```javascript
localStorage.setItem('offline_mode', 'true');
window.location.reload();
```

## 📊 Performance Features

### Frontend Optimizations
- ✅ Code splitting (vendor, router, ui chunks)
- ✅ Tree shaking for smaller bundles
- ✅ Minification and compression
- ✅ Asset optimization
- ✅ Lazy loading support

### Backend Optimizations
- ✅ Multiple worker processes
- ✅ Request limiting
- ✅ Connection pooling
- ✅ Graceful shutdown
- ✅ Health monitoring

## 🐛 Troubleshooting

### Common Issues

1. **CORS Errors**
   - Check `ALLOWED_ORIGINS` in backend `.env`
   - Verify frontend and backend URLs match

2. **OAuth Redirect Issues**
   - Ensure callback URLs are configured correctly
   - Check OAuth provider settings

3. **Database Connection Issues**
   - Verify Supabase credentials
   - Check network connectivity

4. **Build Issues**
   - Run `npm install` before building
   - Check Node.js version (18+ required)

### Debug Commands

```bash
# Check backend status
curl http://localhost:5004/health

# Check frontend build
ls -la dist/

# Test database connection
python -c "from supabase_client import supabase_manager; print(supabase_manager.test_connection())"

# Check environment variables
python -c "import os; print('SUPABASE_URL:', os.getenv('SUPABASE_URL'))"
```

## 📈 Monitoring

### Health Check Endpoints
- `/health` - Basic health check
- `/ping` - Simple ping response
- `/debug` - Debug information (development only)

### Log Monitoring
- Backend logs: Check Gunicorn output
- Frontend errors: Check browser console
- Network issues: Check proxy configuration

## 🎉 Success!

Once deployed, your Tubby AI application will be:
- ✅ Production-ready and optimized
- ✅ Scalable and maintainable
- ✅ Secure and monitored
- ✅ Resilient with offline mode
- ✅ Fast and responsive

## 📞 Support

For deployment issues:
1. Check the troubleshooting section
2. Review logs and error messages
3. Verify environment configuration
4. Test locally before deploying
5. Use offline mode as a fallback

**Remember**: The offline mode ensures your app works even if the backend is temporarily unavailable! 