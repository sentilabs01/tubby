# 🚀 Production Environment Setup for Tubbyai.com

This guide provides the exact environment variables needed for deploying Tubby AI to production at `Tubbyai.com`.

## 🔧 **Required Environment Variables**

### **Frontend Environment Variables (Vite)**

Set these in your Amplify console under "Environment variables":

```bash
# Frontend Configuration
VITE_API_URL=https://tubbyai.com
```

### **Backend Environment Variables (Flask)**

Set these in your Amplify console under "Environment variables":

```bash
# Flask Configuration
FLASK_ENV=production
SECRET_KEY=your-secure-secret-key-here
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

# Redis Configuration
REDIS_HOST=your-redis-host
REDIS_PORT=6379

# Container URLs
GEMINI_CLI_URL_1=http://localhost:8001
GEMINI_CLI_URL_2=http://localhost:8002

# CORS Configuration
ALLOWED_ORIGINS=https://tubbyai.com,http://localhost:3001

# Backend URL (for OAuth callbacks)
BACKEND_URL=https://api.tubbyai.com
```

## 🔐 **OAuth Provider Configuration**

### **Google OAuth Setup**

1. **Google Cloud Console:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing
   - Enable Google+ API
   - Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client IDs"
   - Set Application Type to "Web application"
   - Add Authorized redirect URIs:
     ```
     https://tubbyai.com/auth/callback
     http://localhost:3001/auth/callback (for development)
     ```

2. **Supabase Configuration:**
   - Go to your Supabase Dashboard
   - Navigate to Authentication → Providers
   - Enable Google provider
   - Add your Google Client ID and Client Secret
   - Set redirect URL to: `https://tubbyai.com/auth/callback`

### **GitHub OAuth Setup**

1. **GitHub Developer Settings:**
   - Go to [GitHub Developer Settings](https://github.com/settings/developers)
   - Click "New OAuth App"
   - Set Application name: "Tubby AI"
   - Set Homepage URL: `https://tubbyai.com`
   - Set Authorization callback URL: `https://tubbyai.com/auth/callback`

2. **Supabase Configuration:**
   - Go to your Supabase Dashboard
   - Navigate to Authentication → Providers
   - Enable GitHub provider
   - Add your GitHub Client ID and Client Secret
   - Set redirect URL to: `https://tubbyai.com/auth/callback`

## 🌐 **Domain Configuration**

### **Frontend Domain**
- **Production URL**: `https://tubbyai.com`
- **Development URL**: `http://localhost:3001`

### **Backend Domain**
- **Production URL**: `https://api.tubbyai.com`
- **Development URL**: `http://localhost:5004`

## 🔒 **Security Considerations**

### **SSL/HTTPS**
- Ensure all production URLs use HTTPS
- Configure SSL certificates for both domains
- Set secure cookies in production

### **CORS Configuration**
- Only allow your production domain: `https://tubbyai.com`
- Include localhost for development: `http://localhost:3001`

### **Environment Variables**
- Never commit sensitive data to Git
- Use Amplify's environment variable management
- Rotate keys regularly

## 🚀 **Deployment Steps**

1. **Set Environment Variables in Amplify:**
   - Copy the environment variables above
   - Add them to your Amplify app settings
   - Ensure all URLs point to production domains

2. **Configure OAuth Providers:**
   - Update Google OAuth redirect URLs
   - Update GitHub OAuth redirect URLs
   - Configure Supabase authentication settings

3. **Test Authentication Flow:**
   - Test Google OAuth login
   - Test GitHub OAuth login
   - Test guest authentication
   - Verify redirect URLs work correctly

4. **Monitor Deployment:**
   - Check Amplify build logs
   - Test all authentication endpoints
   - Verify CORS is working correctly

## 🐛 **Troubleshooting**

### **Common Issues**

1. **OAuth Redirect Errors:**
   - Verify redirect URLs in OAuth providers
   - Check that `BACKEND_URL` is set correctly
   - Ensure CORS includes your domain

2. **CORS Errors:**
   - Verify `ALLOWED_ORIGINS` includes your domain
   - Check that frontend and backend URLs match
   - Ensure HTTPS is used in production

3. **Authentication Failures:**
   - Check Supabase configuration
   - Verify OAuth provider settings
   - Check environment variables are set correctly

### **Debug Commands**

```bash
# Test OAuth callback
curl -I https://tubbyai.com/auth/callback

# Test health endpoint
curl https://api.tubbyai.com/health

# Check CORS headers
curl -H "Origin: https://tubbyai.com" -H "Access-Control-Request-Method: POST" -X OPTIONS https://api.tubbyai.com/auth/callback
```

## ✅ **Verification Checklist**

- [ ] Environment variables set in Amplify
- [ ] OAuth providers configured with correct redirect URLs
- [ ] CORS settings include production domain
- [ ] SSL certificates configured
- [ ] Authentication flow tested
- [ ] All redirect URLs working
- [ ] No hardcoded localhost URLs remaining

## 📞 **Support**

If you encounter issues:
1. Check Amplify build logs
2. Verify environment variables
3. Test OAuth configuration
4. Review CORS settings
5. Check domain configuration

Your Tubby AI application should now work correctly in production at `Tubbyai.com`! 🎉 