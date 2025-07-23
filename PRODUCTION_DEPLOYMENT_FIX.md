# 🚀 Production Deployment Fix for Tubby AI

## 🔍 **Issue Identified**
The frontend was configured to use `https://tubbyai.com` as the API URL instead of the backend URL `https://api.tubbyai.com`, causing:
- 401 Unauthorized errors
- WebSocket connection failures
- JSON parsing errors (receiving HTML instead of JSON)

## ✅ **Fixes Applied**

### 1. **Frontend Environment Variable Fix**
**File**: `amplify-env-variables.txt`
**Change**: Updated `VITE_API_URL` from `https://tubbyai.com` to `https://api.tubbyai.com`

### 2. **Backend CORS Configuration Fix**
**File**: `backend/app.py`
**Changes**:
- Added `https://api.tubbyai.com` to CORS origins
- Updated Socket.IO CORS configuration for WebSocket connections

## 🚀 **Deployment Steps**

### **Step 1: Update Frontend Environment Variables**

#### Option A: Using AWS CLI (Recommended)
```powershell
# Run the update script
.\scripts\update-production-env.ps1
```

#### Option B: Manual Update
1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
2. Select your Tubby AI app
3. Go to **App Settings** → **Environment Variables**
4. Update `VITE_API_URL` to: `https://api.tubbyai.com`
5. Save and redeploy

### **Step 2: Deploy Backend Changes**

#### Using Elastic Beanstalk CLI
```bash
cd backend
eb deploy
```

#### Using AWS Console
1. Go to [Elastic Beanstalk Console](https://console.aws.amazon.com/elasticbeanstalk/)
2. Select your backend environment
3. Upload the updated `app.py` file
4. Deploy the changes

### **Step 3: Verify the Fix**

#### Test Backend Health
```bash
curl https://api.tubbyai.com/health
```

#### Test Authentication Endpoint
```bash
curl https://api.tubbyai.com/auth/user
```

#### Test Frontend
1. Open `https://tubbyai.com`
2. Check browser console for errors
3. Try logging in with Google/GitHub

## 🔧 **Configuration Summary**

### **Frontend (Amplify)**
- **URL**: `https://tubbyai.com`
- **API URL**: `https://api.tubbyai.com`
- **Environment Variable**: `VITE_API_URL=https://api.tubbyai.com`

### **Backend (Elastic Beanstalk)**
- **URL**: `https://api.tubbyai.com`
- **CORS Origins**: `https://tubbyai.com`, `https://api.tubbyai.com`
- **WebSocket**: Enabled for real-time communication

## 🐛 **Expected Results After Fix**

### **Before Fix**
- ❌ 401 Unauthorized errors
- ❌ WebSocket connection failures
- ❌ JSON parsing errors
- ❌ Infinite redirect loops

### **After Fix**
- ✅ Successful authentication
- ✅ WebSocket connections working
- ✅ Proper JSON responses
- ✅ Clean login flow

## 📋 **Verification Checklist**

- [ ] Frontend loads without console errors
- [ ] Google OAuth login works
- [ ] GitHub OAuth login works
- [ ] Guest login works
- [ ] WebSocket connections establish
- [ ] Real-time terminal communication works
- [ ] API calls return proper JSON responses

## 🆘 **Troubleshooting**

### **If Issues Persist**

1. **Clear Browser Cache**
   - Hard refresh (Ctrl+F5)
   - Clear cookies for the domain

2. **Check Environment Variables**
   ```bash
   # Verify Amplify environment variables
   aws amplify get-app --app-id YOUR_APP_ID
   ```

3. **Check Backend Logs**
   ```bash
   # View Elastic Beanstalk logs
   eb logs
   ```

4. **Test Backend Directly**
   ```bash
   curl -v https://api.tubbyai.com/ping
   curl -v https://api.tubbyai.com/auth/user
   ```

## 📞 **Support**

If you continue to experience issues after applying these fixes:
1. Check the browser console for specific error messages
2. Verify all environment variables are set correctly
3. Ensure both frontend and backend are deployed with the latest changes 