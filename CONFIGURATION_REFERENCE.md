# 🔧 Tubby AI Configuration Reference

## 📋 **Current Status Summary**

### ✅ **Working Components:**
- **Stripe**: API key and all price IDs working
- **Backend**: Running on port 5004
- **Frontend**: Accessible at `http://192.168.4.22:3001`

### ❌ **Issues to Fix:**
- **Supabase**: Wrong project URL causing DNS errors
- **OAuth**: Redirect URL mismatches

---

## 🗄️ **Supabase Configuration**

### **Current (Broken) Configuration:**
```
URL: https://bemssfbadcfrvzbgjlu.supabase.co ❌ (Doesn't exist)
Anon Key: [Invalid]
Service Role Key: [Invalid]
```

### **Working Configuration (ewrbezytnhuovvmkepeg project):**
```
URL: https://ewrbezytnhuovvmkepeg.supabase.co ✅
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3cmJlenl0bmh1b3Z2bWtlcGVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE5NzQ5NzQsImV4cCI6MjA0NzU1MDk3NH0.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8
Service Role Key: [NEED TO GET FROM DASHBOARD]
```

### **Required Actions:**
1. **Get Service Role Key** from: https://supabase.com/dashboard/project/ewrbezytnhuovvmkepeg/settings/api
2. **Update .env file** with correct keys
3. **Update Amplify environment variables**

---

## 🔐 **OAuth Configuration**

### **Google OAuth:**
```
Client ID: 117261848322-rgs0fd2fsk2emdgcd0jhjv4380rcmibh.apps.googleusercontent.com
Client Secret: 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
```

### **GitHub OAuth:**
```
Client ID: Ov231i0VjZz21dCiQ9oj
Client Secret: 21962b4c088c2d402bb45209c929b58ab93f88ec
```

### **Required Redirect URLs:**

#### **For Local Development:**
- `http://localhost:3001/auth/callback`
- `http://192.168.4.22:3001/auth/callback`

#### **For Production:**
- `https://tubbyai.com/auth/callback`

### **Configuration Locations:**

#### **Google Cloud Console:**
1. Go to: https://console.cloud.google.com/apis/credentials
2. Edit OAuth 2.0 Client ID
3. Add to "Authorized redirect URIs":
   - `http://localhost:3001/auth/callback`
   - `https://tubbyai.com/auth/callback`

#### **GitHub OAuth App:**
1. Go to: https://github.com/settings/developers
2. Edit your OAuth App
3. Set "Authorization callback URL" to: `https://tubbyai.com/auth/callback`

#### **Supabase Auth Settings:**
1. Go to: https://supabase.com/dashboard/project/ewrbezytnhuovvmkepeg/auth/providers
2. Configure Google provider:
   - Redirect URL: `https://tubbyai.com/auth/callback`
3. Configure GitHub provider:
   - Redirect URL: `https://tubbyai.com/auth/callback`

---

## 💳 **Stripe Configuration**

### **Current (Working) Configuration:**
```
Secret Key: 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
Publishable Key: pk_live_51RnFitKoB6ANfJLNwqnyzDzOsUMH2Ie6b7SBOvZucOAUFkyPo0PqCsqZmLZq2Kqpzp3qLQa65KQ0jlrLWP3kXSRp00A1NZSjVt
```

### **Price IDs:**
```
Basic: price_1RnI7vKoB6ANfJLNft6upLIC ($9.99)
Pro: price_1RnI8LKoB6ANfJLNRNuYrViX ($29.99)
Enterprise: price_1RnI9FKoB6ANfJLNWZTZ5M8A ($99.99)
```

---

## 🌐 **Environment Variables**

### **Local (.env file):**
```env
# Supabase (NEEDS UPDATE)
SUPABASE_URL=https://ewrbezytnhuovvmkepeg.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3cmJlenl0bmh1b3Z2bWtlcGVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE5NzQ5NzQsImV4cCI6MjA0NzU1MDk3NH0.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8
SUPABASE_SERVICE_ROLE_KEY=[NEED TO GET]

# OAuth
GOOGLE_CLIENT_ID=117261848322-rgs0fd2fsk2emdgcd0jhjv4380rcmibh.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
GITHUB_CLIENT_ID=Ov231i0VjZz21dCiQ9oj
GITHUB_CLIENT_SECRET=21962b4c088c2d402bb45209c929b58ab93f88ec

# Stripe
STRIPE_SECRET_KEY=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
STRIPE_PUBLISHABLE_KEY=pk_live_51RnFitKoB6ANfJLNwqnyzDzOsUMH2Ie6b7SBOvZucOAUFkyPo0PqCsqZmLZq2Kqpzp3qLQa65KQ0jlrLWP3kXSRp00A1NZSjVt
STRIPE_BASIC_PRICE_ID=price_1RnI7vKoB6ANfJLNft6upLIC
STRIPE_PRO_PRICE_ID=price_1RnI8LKoB6ANfJLNRNuYrViX
STRIPE_ENTERPRISE_PRICE_ID=price_1RnI9FKoB6ANfJLNWZTZ5M8A

# URLs
FRONTEND_URL=https://tubbyai.com
BACKEND_URL=https://api.tubbyai.com
ALLOWED_ORIGINS=https://tubbyai.com,http://localhost:3001
```

### **Amplify Environment Variables:**
- **App ID**: `d34pheadvyr3df`
- **Region**: `us-east-1`
- **Status**: Need to update with correct Supabase configuration

---

## 🚀 **Deployment URLs**

### **Production:**
- **Frontend**: `https://tubbyai.com`
- **Backend**: `https://api.tubbyai.com` (when deployed)

### **Local Development:**
- **Frontend**: `http://localhost:3001` or `http://192.168.4.22:3001`
- **Backend**: `http://localhost:5004`

---

## ✅ **Action Items**

### **Priority 1 (Critical):**
1. **Get Supabase Service Role Key** from `ewrbezytnhuovvmkepeg` project
2. **Update .env file** with correct Supabase configuration
3. **Test OAuth flow** locally

### **Priority 2 (Before Deployment):**
1. **Update Google OAuth** redirect URLs
2. **Update GitHub OAuth** redirect URL
3. **Update Supabase Auth** provider settings
4. **Update Amplify** environment variables

### **Priority 3 (Deployment):**
1. **Deploy backend** to Amplify
2. **Test full functionality** in production
3. **Verify all OAuth flows** work

---

## 🔍 **Testing Checklist**

### **Local Testing:**
- [ ] Backend health check: `curl http://localhost:5004/health`
- [ ] Supabase connection test
- [ ] OAuth flow test (Google)
- [ ] OAuth flow test (GitHub)
- [ ] Stripe payment test
- [ ] User authentication test

### **Production Testing:**
- [ ] Frontend loads at `https://tubbyai.com`
- [ ] OAuth redirects work correctly
- [ ] Payment flow works
- [ ] User management works
- [ ] Database operations work

---

## 📞 **Support Links**

- **Supabase Dashboard**: https://supabase.com/dashboard/project/ewrbezytnhuovvmkepeg
- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials
- **GitHub OAuth Apps**: https://github.com/settings/developers
- **Stripe Dashboard**: https://dashboard.stripe.com/
- **AWS Amplify Console**: https://console.aws.amazon.com/amplify/ 