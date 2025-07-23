# AWS Amplify + GitHub Setup Guide

## 🚀 Complete Deployment Workflow

### **Architecture**
- **Frontend**: GitHub → AWS Amplify (automatic deployment)
- **Backend**: AWS CLI → Elastic Beanstalk (manual deployment)

## 📋 **Step 1: Backend Deployment (Elastic Beanstalk)**

### **1.1 Deploy Backend First**
```powershell
# Deploy backend to Elastic Beanstalk
.\deploy-backend-eb.ps1 -CreateEnvironment
```

This will:
- ✅ Create EB application and environment
- ✅ Deploy Flask backend with Gunicorn
- ✅ Set up health checks and monitoring
- ✅ Provide backend URL

### **1.2 Configure Environment Variables**
After deployment, go to AWS Console → Elastic Beanstalk → Your Environment → Configuration → Software:

**Required Environment Variables:**
```env
FLASK_ENV=production
PORT=5004
HOST=0.0.0.0
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
STRIPE_WEBHOOK_SECRET=your-stripe-webhook-secret
STRIPE_BASIC_PRICE_ID=price_1RnI7vKoB6ANfJLNft6upLIC
STRIPE_PRO_PRICE_ID=price_1RnI8LBKoB6ANfJLNRNUyRVIX
STRIPE_ENTERPRISE_PRICE_ID=price_1RnI9FKoB6ANfJLNwZTZ5M8A
SECRET_KEY=your-secret-key-here
ALLOWED_ORIGINS=https://your-amplify-domain.amplifyapp.com
BACKEND_URL=https://your-eb-environment.elasticbeanstalk.com
```

### **1.3 Get Backend URL**
After deployment, note your backend URL:
```
https://your-eb-environment.elasticbeanstalk.com
```

## 📋 **Step 2: Frontend Setup (GitHub + Amplify)**

### **2.1 Push Code to GitHub**
```bash
# Initialize git if not already done
git init
git add .
git commit -m "Initial commit for Amplify deployment"

# Add your GitHub repository
git remote add origin https://github.com/yourusername/tubby-ai.git
git push -u origin main
```

### **2.2 Create Environment Variables File**
Create `.env.production` in your project root:
```env
# Backend API URL (from EB deployment)
VITE_API_URL=https://your-eb-environment.elasticbeanstalk.com

# Supabase Configuration
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key

# OAuth Configuration
VITE_GOOGLE_CLIENT_ID=your-google-client-id
VITE_GITHUB_CLIENT_ID=your-github-client-id

# Stripe Configuration
VITE_STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
```

### **2.3 Set Up AWS Amplify**

#### **Method 1: AWS Console**
1. Go to AWS Amplify Console
2. Click "New app" → "Host web app"
3. Choose "GitHub" as repository source
4. Connect your GitHub account
5. Select your repository: `yourusername/tubby-ai`
6. Choose branch: `main`
7. Build settings will be auto-detected from `amplify.yml`

#### **Method 2: Amplify CLI**
```bash
# Install Amplify CLI
npm install -g @aws-amplify/cli

# Initialize Amplify
amplify init

# Add hosting
amplify add hosting

# Push to Amplify
amplify push
```

### **2.4 Configure Amplify Environment Variables**
In Amplify Console → Your App → Environment Variables:

**Build-time Environment Variables:**
```env
VITE_API_URL=https://your-eb-environment.elasticbeanstalk.com
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
VITE_GOOGLE_CLIENT_ID=your-google-client-id
VITE_GITHUB_CLIENT_ID=your-github-client-id
VITE_STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
```

## 📋 **Step 3: Configure CORS and Domains**

### **3.1 Update Backend CORS**
In your EB environment variables, update `ALLOWED_ORIGINS`:
```env
ALLOWED_ORIGINS=https://your-amplify-domain.amplifyapp.com,https://yourdomain.com
```

### **3.2 Update OAuth Callback URLs**
In your OAuth providers (Google, GitHub), add callback URLs:
```
https://your-eb-environment.elasticbeanstalk.com/auth/callback
```

## 📋 **Step 4: Test Deployment**

### **4.1 Test Backend**
```bash
# Health check
curl https://your-eb-environment.elasticbeanstalk.com/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### **4.2 Test Frontend**
Visit your Amplify URL:
```
https://your-amplify-domain.amplifyapp.com
```

## 🔄 **Continuous Deployment Workflow**

### **Frontend Updates (Automatic)**
1. Make changes to your code
2. Push to GitHub `main` branch
3. Amplify automatically builds and deploys
4. Changes are live in minutes

### **Backend Updates (Manual)**
```powershell
# Deploy backend changes
.\deploy-backend-eb.ps1
```

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **1. Build Failures**
- Check Amplify build logs
- Verify `amplify.yml` configuration
- Ensure all dependencies are in `package.json`

#### **2. CORS Errors**
- Verify `ALLOWED_ORIGINS` in EB environment variables
- Check that frontend and backend URLs match

#### **3. Environment Variables Not Loading**
- Ensure variables are set in Amplify Console
- Check that variables start with `VITE_` for frontend

#### **4. Backend Connection Issues**
- Verify backend URL in frontend environment variables
- Check EB environment health
- Test backend endpoints directly

### **Debug Commands**

#### **Check Backend Status**
```bash
# EB status
eb status

# EB logs
eb logs

# Health check
curl https://your-eb-environment.elasticbeanstalk.com/health
```

#### **Check Frontend Build**
```bash
# Local build test
npm run build:prod

# Check Amplify build logs in AWS Console
```

## 🎯 **Production Checklist**

### **Backend (Elastic Beanstalk)**
- [ ] Environment deployed and healthy
- [ ] Environment variables configured
- [ ] CORS settings updated
- [ ] Health check endpoint working
- [ ] SSL certificate configured (if using custom domain)

### **Frontend (Amplify)**
- [ ] GitHub repository connected
- [ ] Build successful
- [ ] Environment variables set
- [ ] App accessible via Amplify URL
- [ ] Custom domain configured (optional)

### **Integration**
- [ ] Frontend can connect to backend
- [ ] OAuth callbacks working
- [ ] API endpoints responding
- [ ] Offline mode functional

## 🚀 **Deployment Commands Summary**

```bash
# 1. Deploy backend
.\deploy-backend-eb.ps1 -CreateEnvironment

# 2. Push to GitHub
git add .
git commit -m "Ready for Amplify deployment"
git push origin main

# 3. Amplify will auto-deploy from GitHub

# 4. Update backend (when needed)
.\deploy-backend-eb.ps1
```

## 🎉 **Success!**

Once deployed, you'll have:
- **Frontend**: `https://your-amplify-domain.amplifyapp.com`
- **Backend**: `https://your-eb-environment.elasticbeanstalk.com`
- **Automatic deployments** from GitHub
- **Scalable infrastructure** on AWS
- **Offline mode** for resilience

Your Tubby AI application is now production-ready with enterprise-grade deployment! 🚀 