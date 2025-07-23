# 🔧 Auth & Redirect Issues Fix Guide

## 🚨 **Current Issues Identified**

Based on the code review, here are the main problems causing auth and redirect issues:

### **1. CORS Configuration Conflicts**
- Merge conflicts in `backend/app.py` CORS settings
- Missing production domain URLs
- Inconsistent CORS configuration

### **2. Environment Variable Issues**
- `FRONTEND_URL` and `BACKEND_URL` not properly set
- OAuth callback URLs not configured correctly
- Missing production environment variables

### **3. OAuth Flow Problems**
- Callback URLs pointing to wrong domains
- Token handling issues in production
- Session configuration problems

## 🔧 **Step-by-Step Fix**

### **Step 1: Fix CORS Configuration**

First, let's fix the merge conflicts in `backend/app.py`:

```python
# Replace the CORS configuration (around line 45-50) with:
CORS(app, origins=[
    'http://localhost:3001', 'http://localhost:3003', 'http://localhost:3010', 
    'http://localhost:3015', 'http://localhost:4173',
    'https://tubbyai.com', 'https://www.tubbyai.com',
    'https://your-amplify-domain.amplifyapp.com',  # Add your Amplify domain
    'https://your-eb-environment.elasticbeanstalk.com',  # Add your EB domain
    'https://accounts.google.com', 'https://oauthchooseaccount.google.com'
], supports_credentials=True, methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])

socketio = SocketIO(app, cors_allowed_origins=[
    'http://localhost:3001', 'http://localhost:3003', 'http://localhost:3010', 
    'http://localhost:3015', 'http://localhost:4173',
    'https://tubbyai.com', 'https://www.tubbyai.com',
    'https://your-amplify-domain.amplifyapp.com',  # Add your Amplify domain
    'https://your-eb-environment.elasticbeanstalk.com',  # Add your EB domain
    'https://accounts.google.com', 'https://oauthchooseaccount.google.com'
])
```

### **Step 2: Update Environment Variables**

#### **Backend (Elastic Beanstalk)**
Go to AWS Console → Elastic Beanstalk → Your Environment → Configuration → Software → Environment properties:

```env
# Core Configuration
FLASK_ENV=production
PORT=5004
HOST=0.0.0.0
SECRET_KEY=your-secret-key-here

# Frontend and Backend URLs (CRITICAL)
FRONTEND_URL=https://your-amplify-domain.amplifyapp.com
BACKEND_URL=https://your-eb-environment.elasticbeanstalk.com

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
ALLOWED_ORIGINS=https://your-amplify-domain.amplifyapp.com,https://tubbyai.com,https://www.tubbyai.com
```

#### **Frontend (Amplify)**
Go to AWS Amplify Console → Your App → Environment Variables:

```env
# Backend API URL (CRITICAL)
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

### **Step 3: Update OAuth Provider Settings**

#### **Google OAuth (Google Cloud Console)**
1. Go to Google Cloud Console → APIs & Services → Credentials
2. Edit your OAuth 2.0 Client ID
3. Add these Authorized redirect URIs:
   ```
   https://your-eb-environment.elasticbeanstalk.com/auth/callback
   https://your-eb-environment.elasticbeanstalk.com/auth/google/callback
   ```

#### **GitHub OAuth (GitHub Developer Settings)**
1. Go to GitHub → Settings → Developer settings → OAuth Apps
2. Edit your OAuth App
3. Update Authorization callback URL:
   ```
   https://your-eb-environment.elasticbeanstalk.com/auth/callback
   ```

#### **Supabase OAuth Settings**
1. Go to Supabase Dashboard → Authentication → URL Configuration
2. Set Site URL:
   ```
   https://your-amplify-domain.amplifyapp.com
   ```
3. Add Redirect URLs:
   ```
   https://your-eb-environment.elasticbeanstalk.com/auth/callback
   https://your-amplify-domain.amplifyapp.com/auth/callback
   ```

### **Step 4: Fix Session Configuration**

Update the session configuration in `backend/app.py`:

```python
# Around line 40, update session configuration:
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
app.config["SESSION_COOKIE_SAMESITE"] = "None"
app.config["SESSION_COOKIE_SECURE"] = True
app.config["SESSION_COOKIE_DOMAIN"] = None  # Let Flask handle domain
app.config["SESSION_COOKIE_HTTPONLY"] = True
```

### **Step 5: Update Callback Handling**

The callback route needs to handle both development and production URLs properly. The current implementation should work, but make sure the environment variables are set correctly.

## 🧪 **Testing the Fix**

### **1. Test Backend Health**
```bash
curl https://your-eb-environment.elasticbeanstalk.com/health
```

### **2. Test CORS**
```bash
curl -H "Origin: https://your-amplify-domain.amplifyapp.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://your-eb-environment.elasticbeanstalk.com/auth/user
```

### **3. Test OAuth Flow**
1. Go to your Amplify frontend
2. Click "Sign in with Google" or "Sign in with GitHub"
3. Complete the OAuth flow
4. Check if you're redirected back properly

### **4. Test API Calls**
```bash
# Test authenticated endpoint
curl -H "Origin: https://your-amplify-domain.amplifyapp.com" \
     -H "Content-Type: application/json" \
     -X GET \
     https://your-eb-environment.elasticbeanstalk.com/auth/user
```

## 🐛 **Common Issues and Solutions**

### **Issue 1: CORS Errors**
**Symptoms**: Browser console shows CORS errors
**Solution**: 
- Update CORS origins in backend
- Ensure frontend URL is in allowed origins
- Check that requests include credentials

### **Issue 2: Redirect Loop**
**Symptoms**: OAuth redirects keep looping
**Solution**:
- Check OAuth callback URLs in provider settings
- Verify `FRONTEND_URL` and `BACKEND_URL` environment variables
- Ensure callback route is working

### **Issue 3: Session Not Persisting**
**Symptoms**: User gets logged out immediately
**Solution**:
- Check session configuration
- Verify `SECRET_KEY` is set
- Ensure cookies are being set properly

### **Issue 4: Token Verification Fails**
**Symptoms**: "Failed to verify token" errors
**Solution**:
- Check Supabase configuration
- Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- Ensure OAuth is properly configured in Supabase

## 🔄 **Deployment Commands**

### **Update Backend**
```powershell
# Deploy backend changes
.\deploy-backend-eb.ps1
```

### **Update Frontend**
```bash
# Push changes to GitHub (Amplify will auto-deploy)
git add .
git commit -m "Fix auth and redirect issues"
git push origin main
```

## 📋 **Checklist**

- [ ] CORS configuration updated with production domains
- [ ] Environment variables set in EB Console
- [ ] Environment variables set in Amplify Console
- [ ] OAuth callback URLs updated in providers
- [ ] Supabase OAuth settings configured
- [ ] Session configuration updated
- [ ] Backend redeployed
- [ ] Frontend redeployed
- [ ] Health check passes
- [ ] OAuth flow tested
- [ ] API calls working

## 🎯 **Quick Fix Script**

Run this to apply the fixes:

```powershell
# 1. Fix CORS configuration
# (Manually update backend/app.py as shown above)

# 2. Deploy backend
.\deploy-backend-eb.ps1

# 3. Push frontend changes
git add .
git commit -m "Fix auth configuration"
git push origin main

# 4. Update environment variables in AWS Console
# (Follow the steps above)
```

## 🚨 **Critical Notes**

1. **Environment Variables**: The `FRONTEND_URL` and `BACKEND_URL` are critical for OAuth to work
2. **CORS Origins**: Must include your exact Amplify and EB domains
3. **OAuth Callbacks**: Must point to your EB backend, not the frontend
4. **HTTPS**: All production URLs must use HTTPS
5. **Session Cookies**: Must be configured for cross-domain requests

Once these fixes are applied, your auth and redirect issues should be resolved! 🎉 