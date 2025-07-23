# 🚀 Amplify Deployment Checklist

## Pre-Deployment Checklist

### ✅ Environment Setup
- [ ] Copy `env.example` to `.env` and fill in values
- [ ] Set up Supabase production database
- [ ] Configure Redis instance (ElastiCache recommended)
- [ ] Set up OAuth applications (Google, GitHub)
- [ ] Configure Stripe production keys

### ✅ Code Preparation
- [ ] All tests passing locally
- [ ] Frontend builds successfully (`npm run build`)
- [ ] Backend imports without errors
- [ ] Health check endpoint working (`/health`)
- [ ] All environment variables configured

### ✅ AWS Amplify Setup
- [ ] AWS account created and configured
- [ ] GitHub repository connected to Amplify
- [ ] Environment variables added to Amplify console
- [ ] Build settings configured (amplify.yml detected)
- [ ] Custom domain configured (optional)

## Deployment Steps

### 1. Push to GitHub
```bash
git add .
git commit -m "Prepare for Amplify deployment"
git push origin main
```

### 2. Monitor Amplify Build
- [ ] Check build logs in Amplify console
- [ ] Verify frontend deployment
- [ ] Verify backend deployment
- [ ] Test health check endpoint

### 3. Post-Deployment Verification
- [ ] Frontend loads correctly
- [ ] Backend API responds
- [ ] OAuth authentication works
- [ ] Database connections established
- [ ] Redis connections working
- [ ] Stripe integration functional

## Environment Variables Required

### Frontend (Vite)
```
VITE_API_URL=https://your-backend-domain.com
```

### Backend (Flask)
```
FLASK_ENV=production
SECRET_KEY=your-secure-secret-key
PORT=5004
HOST=0.0.0.0

# Supabase Configuration
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# OAuth Configuration
GOOGLE_CLIENT_ID=117261848322-rgs0fd2fsk2emdgcd0jhjv4380rcmibh.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret
GITHUB_CLIENT_ID=Ov23li0VjZz21dCiQ9oj
GITHUB_CLIENT_SECRET=your-github-client-secret

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_WEBHOOK_SECRET=your-stripe-webhook-secret
STRIPE_BASIC_PRICE_ID=price_1RnI7vKoB6ANfJLNft6upLIC
STRIPE_PRO_PRICE_ID=price_1RnI8LBKoB6ANfJLNRNUyRVIX
STRIPE_ENTERPRISE_PRICE_ID=price_1RnI9FKoB6ANfJLNwZTZ5M8A

# Redis Configuration
REDIS_HOST=your-redis-host
REDIS_PORT=6379

# Container URLs
GEMINI_CLI_URL_1=http://localhost:8001
GEMINI_CLI_URL_2=http://localhost:8002

# CORS Configuration
ALLOWED_ORIGINS=https://tubbyai.com,http://localhost:3001
BACKEND_URL=https://api.tubbyai.com
FRONTEND_URL=https://tubbyai.com
```

## Quick Commands

### Local Testing
```bash
# Test frontend build
npm run build

# Test backend
cd backend
python -c "import app_production; print('✅ Backend ready')"

# Run deployment script (Windows)
.\scripts\deploy-amplify.ps1

# Run deployment script (Linux/Mac)
./scripts/deploy-amplify.sh
```

### Deployment Verification
```bash
# Test health endpoint
curl https://your-domain.com/health

# Check build status
# Visit Amplify console
```

## Troubleshooting

### Common Issues
1. **Build Failures**: Check Amplify build logs
2. **Environment Variables**: Verify all required vars are set
3. **CORS Errors**: Check `ALLOWED_ORIGINS` configuration
4. **Database Connection**: Verify Supabase configuration
5. **Redis Connection**: Check Redis host and port

### Support Resources
- [AMPLIFY_DEPLOYMENT_GUIDE.md](AMPLIFY_DEPLOYMENT_GUIDE.md) - Detailed deployment guide
- [AWS Amplify Documentation](https://docs.aws.amazon.com/amplify/)
- [Amplify Console](https://console.aws.amazon.com/amplify/)

## Success Indicators

✅ **Deployment Successful When:**
- Amplify build completes without errors
- Frontend accessible at your domain
- Backend health check returns 200
- OAuth login works
- API calls succeed
- Database operations work
- Real-time features function

🎉 **Ready for Production!** 