# OAuth Setup Instructions for Tubby AI

## Overview
This guide will help you set up Google OAuth and GitHub OAuth for your Tubby AI platform using Supabase Auth.

## Prerequisites
- Supabase project already created
- Access to Google Cloud Console
- GitHub account with developer access

## Step 1: Supabase Auth Configuration

### 1.1 Enable Auth Providers in Supabase

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Authentication** > **Providers**
4. You'll see a list of available providers

### 1.2 Configure Google OAuth

1. **In Supabase Dashboard:**
   - Find "Google" in the providers list
   - Click on it to expand the configuration
   - Toggle "Enable" to turn it on

2. **Get Google OAuth Credentials:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable the Google+ API and Google Identity API:
     - Go to **APIs & Services** > **Library**
     - Search for "Google+ API" and enable it
     - Search for "Google Identity API" and enable it

3. **Configure OAuth Consent Screen:**
   - Go to **APIs & Services** > **OAuth consent screen**
   - Choose "External" user type
   - Fill in the required information:
     - **App name**: "Tubby AI Agent Platform"
     - **User support email**: Your email
     - **Developer contact information**: Your email
   - Add scopes: `email`, `profile`, `openid`
   - Add test users if needed (for development)

4. **Create OAuth Credentials:**
   - Go to **APIs & Services** > **Credentials**
   - Click **Create Credentials** > **OAuth 2.0 Client IDs**
   - Choose "Web application"
   - Add authorized redirect URIs:
     - `https://your-project-ref.supabase.co/auth/v1/callback`
     - Replace `your-project-ref` with your actual Supabase project reference
   - Copy the **Client ID** and **Client Secret**

5. **Add Credentials to Supabase:**
   - Go back to Supabase Dashboard > **Authentication** > **Providers** > **Google**
   - Paste your Google Client ID and Client Secret
   - Save the configuration

### 1.3 Configure GitHub OAuth

1. **In Supabase Dashboard:**
   - Find "GitHub" in the providers list
   - Click on it to expand the configuration
   - Toggle "Enable" to turn it on

2. **Create GitHub OAuth App:**
   - Go to [GitHub Developer Settings](https://github.com/settings/developers)
   - Click **New OAuth App**
   - Fill in the application details:
     - **Application name**: "Tubby AI Agent Platform"
     - **Homepage URL**: `http://localhost:5173` (for development)
     - **Authorization callback URL**: `https://your-project-ref.supabase.co/auth/v1/callback`
     - Replace `your-project-ref` with your actual Supabase project reference
   - Click **Register application**
   - Copy the **Client ID** and **Client Secret**

3. **Add Credentials to Supabase:**
   - Go back to Supabase Dashboard > **Authentication** > **Providers** > **GitHub**
   - Paste your GitHub Client ID and Client Secret
   - Save the configuration

## Step 2: Environment Variables

Update your `.env` file in the backend directory:

```env
# Supabase Configuration (you already have these)
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key

# Frontend URL (for OAuth redirects)
FRONTEND_URL=http://localhost:5173

# JWT Configuration
JWT_SECRET_KEY=your_jwt_secret_key_here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Stripe Configuration (if you're using payments)
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Subscription Plans (if you're using payments)
STRIPE_BASIC_PRICE_ID=price_basic_plan_id
STRIPE_PRO_PRICE_ID=price_pro_plan_id
STRIPE_ENTERPRISE_PRICE_ID=price_enterprise_plan_id
```

## Step 3: Database Schema

Run the updated schema in your Supabase SQL editor:

```sql
-- The schema.sql file has been updated with the users table
-- Run the entire schema.sql file in your Supabase SQL editor
```

## Step 4: Testing

### 4.1 Test OAuth Flow

1. Start your backend server:
   ```bash
   cd backend
   python app.py
   ```

2. Start your frontend:
   ```bash
   npm run dev
   ```

3. Navigate to your application
4. Click "Sign in with Google" or "Sign in with GitHub"
5. Complete the OAuth flow
6. Verify that you're redirected back to the application

### 4.2 Test API Key Management

1. Sign in with any provider
2. Open the Settings panel (gear icon)
3. Try adding API keys for Gemini, Claude, and OpenAI
4. Verify that the keys are saved and can be retrieved

### 4.3 Test Guest User

1. Click "Continue as Guest"
2. Verify that you can access the application
3. Try adding API keys (should show guest notice)
4. Verify that subscription features are restricted

## Step 5: Production Configuration

### 5.1 Update OAuth Redirect URLs

For production, update the redirect URLs in both Google and GitHub:

**Google Cloud Console:**
- Add: `https://yourdomain.com/auth/callback`

**GitHub OAuth App:**
- Update Homepage URL: `https://yourdomain.com`
- Update Authorization callback URL: `https://your-project-ref.supabase.co/auth/v1/callback`

### 5.2 Environment Variables

Update your production environment variables:

```env
FRONTEND_URL=https://yourdomain.com
JWT_SECRET_KEY=your_very_secure_production_secret
```

## Troubleshooting

### Common Issues

1. **"Invalid redirect URI" error:**
   - Make sure the redirect URI in Google/GitHub matches exactly with your Supabase callback URL
   - Check that your Supabase project reference is correct

2. **"Client ID not found" error:**
   - Verify that the Client ID and Secret are correctly copied to Supabase
   - Check that the OAuth provider is enabled in Supabase

3. **"User not found" error:**
   - Make sure the database schema has been applied
   - Check that the users table exists with the correct structure

4. **API keys not saving:**
   - Verify that the user is authenticated
   - Check that the Supabase connection is working
   - Ensure the api_keys table exists and has the correct RLS policies

### Debug Steps

1. Check browser console for JavaScript errors
2. Check backend logs for Python errors
3. Verify Supabase connection in the dashboard
4. Test OAuth flow in incognito mode
5. Check that all environment variables are set correctly

## Security Considerations

1. **Never commit API keys to version control**
2. **Use environment variables for all secrets**
3. **Enable HTTPS in production**
4. **Set up proper CORS configuration**
5. **Implement rate limiting**
6. **Monitor authentication logs**

## Next Steps

Once OAuth is working:

1. Test the complete user flow
2. Set up Stripe for payments (if needed)
3. Configure email notifications
4. Set up monitoring and logging
5. Deploy to production

## Support

If you encounter issues:

1. Check the Supabase documentation
2. Review the Google OAuth documentation
3. Check the GitHub OAuth documentation
4. Look at the browser network tab for failed requests
5. Check the backend logs for detailed error messages 