# Tubby AI Production Deployment Guide

This guide provides comprehensive instructions for deploying Tubby AI to production environments.

## 🚀 Quick Start

### 1. Build and Package (Recommended)

```bash
# On Linux/Mac
chmod +x deploy-production.sh
./deploy-production.sh

# On Windows
.\deploy-production.ps1
```

### 2. Manual Build

```bash
# Frontend
npm run build:prod

# Backend
cd backend
pip install -r requirements_production.txt
```

## 📋 Prerequisites

### Required Tools
- Node.js 18+ and npm
- Python 3.8+
- Git
- AWS CLI (for AWS deployment)

### Required Services
- Supabase (Database & Auth)
- Stripe (Payments)
- AWS Amplify (Frontend hosting)
- AWS Elastic Beanstalk (Backend hosting)

## 🔧 Environment Configuration

### Frontend Environment Variables

Create `.env.production` in the root directory:

```env
# API Configuration
VITE_API_URL=https://api.tubbyai.com
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key

# OAuth Configuration
VITE_GOOGLE_CLIENT_ID=your-google-client-id
VITE_GITHUB_CLIENT_ID=your-github-client-id

# Stripe Configuration
VITE_STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
```

### Backend Environment Variables

Create `.env` in the `backend` directory:

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
ALLOWED_ORIGINS=https://tubbyai.com,https://www.tubbyai.com

# Backend URL (for OAuth callbacks)
BACKEND_URL=https://api.tubbyai.com
```

## 🏗️ Build Process

### Frontend Build

The frontend uses Vite for building:

```bash
# Development build
npm run build

# Production build (optimized)
npm run build:prod
```

**Build Features:**
- Code splitting and lazy loading
- Tree shaking for smaller bundles
- Minification and compression
- Source maps (disabled in production)
- Asset optimization

### Backend Build

The backend uses Gunicorn for production:

```bash
cd backend
pip install -r requirements_production.txt
python start_production.py
```

**Production Features:**
- Eventlet worker class for WebSocket support
- Multiple worker processes
- Request limiting and security
- Health checks and monitoring
- Graceful shutdown handling

## 🚀 Deployment Options

### Option 1: AWS Amplify + Elastic Beanstalk

#### Frontend (AWS Amplify)

1. **Initialize Amplify Project:**
```bash
amplify init
```

2. **Add Hosting:**
```bash
amplify add hosting
```

3. **Deploy:**
```bash
amplify publish
```

#### Backend (AWS Elastic Beanstalk)

1. **Initialize EB Project:**
```bash
cd backend
eb init
```

2. **Create Environment:**
```bash
eb create tubby-backend-prod
```

3. **Deploy:**
```bash
eb deploy
```

### Option 2: Docker Deployment

#### Frontend Dockerfile

```dockerfile
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build:prod

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### Backend Dockerfile

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements_production.txt .
RUN pip install -r requirements_production.txt
COPY . .
EXPOSE 5004
CMD ["python", "start_production.py"]
```

### Option 3: Manual Server Deployment

1. **Upload Files:**
```bash
# Upload frontend build
scp -r dist/* user@server:/var/www/tubby/

# Upload backend
scp -r backend/* user@server:/opt/tubby-backend/
```

2. **Configure Web Server:**
```nginx
# Nginx configuration
server {
    listen 80;
    server_name tubbyai.com;
    
    location / {
        root /var/www/tubby;
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://localhost:5004;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🔍 Health Checks and Monitoring

### Frontend Health Check

```javascript
// Check if app loads correctly
fetch('/health')
  .then(response => response.json())
  .then(data => console.log('Frontend healthy:', data));
```

### Backend Health Check

```bash
# Check backend status
curl https://api.tubbyai.com/health

# Expected response
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z",
  "version": "1.0.0"
}
```

### Monitoring Endpoints

- `/health` - Basic health check
- `/ping` - Simple ping response
- `/debug` - Debug information (development only)

## 🛡️ Security Considerations

### Environment Variables
- Never commit secrets to version control
- Use AWS Secrets Manager or similar for production secrets
- Rotate keys regularly

### CORS Configuration
- Configure allowed origins properly
- Use HTTPS in production
- Validate request origins

### Rate Limiting
- Implement rate limiting on API endpoints
- Monitor for abuse patterns
- Use AWS WAF for additional protection

## 🔧 Offline Mode

The application includes an offline mode feature that:

- Blocks backend calls when backend is unavailable
- Uses cached user data from localStorage
- Provides graceful degradation
- Auto-detects backend health

**Enable Offline Mode:**
```javascript
// Force offline mode
localStorage.setItem('offline_mode', 'true');
window.location.reload();
```

## 📊 Performance Optimization

### Frontend
- Code splitting and lazy loading
- Image optimization
- CDN for static assets
- Service worker for caching

### Backend
- Database connection pooling
- Redis for session storage
- Gunicorn worker optimization
- Request/response compression

## 🐛 Troubleshooting

### Common Issues

1. **CORS Errors:**
   - Check `ALLOWED_ORIGINS` configuration
   - Verify frontend and backend URLs match

2. **OAuth Redirect Issues:**
   - Ensure callback URLs are configured correctly
   - Check OAuth provider settings

3. **Database Connection Issues:**
   - Verify Supabase credentials
   - Check network connectivity
   - Validate database schema

4. **Stripe Integration Issues:**
   - Verify API keys are correct
   - Check webhook configuration
   - Validate price IDs

### Debug Commands

```bash
# Check backend logs
eb logs

# Check frontend build
npm run build:prod --debug

# Test database connection
python -c "from supabase_client import supabase_manager; print(supabase_manager.test_connection())"

# Test Stripe connection
python -c "import stripe; print(stripe.Version)"
```

## 📈 Scaling Considerations

### Frontend Scaling
- Use CDN for static assets
- Implement service workers for caching
- Consider edge computing for global distribution

### Backend Scaling
- Use load balancers
- Implement horizontal scaling
- Use managed databases
- Consider serverless options

## 🔄 CI/CD Pipeline

### GitHub Actions Example

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run build:prod
      - run: npm run test
      - name: Deploy to AWS
        run: |
          # Deploy frontend to Amplify
          amplify publish --yes
          # Deploy backend to EB
          cd backend
          eb deploy
```

## 📞 Support

For deployment issues:

1. Check the troubleshooting section
2. Review logs and error messages
3. Verify environment configuration
4. Test locally before deploying
5. Use the offline mode as a fallback

## 📝 Deployment Checklist

- [ ] Environment variables configured
- [ ] Database schema updated
- [ ] OAuth providers configured
- [ ] Stripe integration tested
- [ ] Frontend build successful
- [ ] Backend health check passing
- [ ] SSL certificates installed
- [ ] Monitoring configured
- [ ] Backup strategy in place
- [ ] Rollback plan prepared 