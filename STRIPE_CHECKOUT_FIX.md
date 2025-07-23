# 🔧 Stripe Checkout Session Fix Guide

## Issues Identified

Based on the console logs and testing, the following issues were found:

### 1. ✅ **CORS Configuration** - FIXED
- **Problem**: Frontend at `https://tubbyai.com` was blocked from accessing `http://localhost:5004`
- **Solution**: Added `https://tubbyai.com` to CORS allowed origins in `backend/app.py`

### 2. ✅ **Hardcoded URLs** - FIXED
- **Problem**: Frontend components had hardcoded `localhost:5004` URLs
- **Solution**: Updated all components to use `VITE_API_URL` environment variable

### 3. ❌ **Backend URL Mismatch** - NEEDS DEPLOYMENT
- **Problem**: Frontend at `https://tubbyai.com` is trying to access local backend at `http://localhost:5004`
- **Solution**: Deploy backend to production or use tunnel service

## Current Status

✅ **Stripe Configuration**: Working correctly
✅ **Backend Health**: Running and responding
✅ **Authentication**: Endpoints working correctly
✅ **CORS**: Fixed for production domain
✅ **Frontend URLs**: Fixed to use environment variables

## Required Actions

### Option 1: Deploy Backend to Production (Recommended)

1. **Deploy the backend** to a production server (e.g., AWS, Google Cloud, Heroku)
2. **Update environment variables**:
   ```env
   VITE_API_URL=https://api.tubbyai.com
   BACKEND_URL=https://api.tubbyai.com
   ```

### Option 2: Use Tunnel Service for Development

1. **Install ngrok**:
   ```bash
   npm install -g ngrok
   ```

2. **Create tunnel**:
   ```bash
   ngrok http 5004
   ```

3. **Update environment variables** with the ngrok URL:
   ```env
   VITE_API_URL=https://your-ngrok-url.ngrok.io
   ```

### Option 3: Local Development Setup

1. **Run frontend locally**:
   ```bash
   npm run dev
   ```

2. **Ensure backend is running**:
   ```bash
   cd backend
   python app.py
   ```

3. **Use local environment**:
   ```env
   VITE_API_URL=http://localhost:5004
   ```

## Environment Configuration

### Production Environment Variables
```env
# Frontend API URL (should point to production backend)
VITE_API_URL=https://api.tubbyai.com

# Backend URL for OAuth callbacks
BACKEND_URL=https://api.tubbyai.com

# CORS Configuration
ALLOWED_ORIGINS=https://tubbyai.com,http://localhost:3001

# Stripe Configuration (already working)
STRIPE_PUBLISHABLE_KEY=pk_live_51RnFitKoB6ANfJLNwqnyzDzOsUMH2Ie6b7SBOvZucOAUFkyPo0PqCsqZmLZq2Kqpzp3qLQa65KQ0jlrLWP3kXSRp00A1NZSjVt
STRIPE_SECRET_KEY=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
```

### Development Environment Variables
```env
# Frontend API URL (for local development)
VITE_API_URL=http://localhost:5004

# Backend URL for OAuth callbacks
BACKEND_URL=http://localhost:5004

# CORS Configuration
ALLOWED_ORIGINS=https://tubbyai.com,http://localhost:3001
```

## Testing the Fix

1. **Update environment variables** with the correct backend URL
2. **Restart the frontend** application
3. **Test authentication** by signing in
4. **Test Stripe checkout** by clicking "Subscribe" on any plan

## Expected Behavior After Fix

- ✅ No CORS errors in console
- ✅ Authentication working properly
- ✅ Stripe checkout sessions created successfully
- ✅ No "Failed to create checkout session" errors

## Troubleshooting

If issues persist:

1. **Check browser console** for any remaining errors
2. **Verify backend is accessible** at the configured URL
3. **Test authentication flow** to ensure user sessions are working
4. **Check Stripe logs** in the Stripe dashboard for any API errors

## Next Steps

1. **Deploy backend to production** or set up tunnel service
2. **Update environment variables** with correct URLs
3. **Test the complete flow** from authentication to payment
4. **Monitor for any remaining issues** 