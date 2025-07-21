# Authentication and Payment Setup Guide

## Environment Variables Required

Create a `.env` file in the backend directory with the following variables:

```env
# Flask Configuration
SECRET_KEY=your-secret-key-change-in-production
FLASK_ENV=development

# Supabase Configuration
SUPABASE_URL=https://ewrbezytnhuovvmkepeg.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3cmJlenl0bmh1b3Z2bWtlcGVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5Njg4MjksImV4cCI6MjA2ODU0NDgyOX0.WagV4Mmud1Co1SvRZ1nCVTLJt7DTIa7KlMqqHcjlHVs

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Docker Configuration
DOCKER_NETWORK=runmvpwithdockerandrequiredtools_ai-agent-network

# Frontend URL (for OAuth redirects)
FRONTEND_URL=http://localhost:5173

# JWT Configuration
JWT_SECRET_KEY=your_jwt_secret_key_here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Subscription Plans (Stripe Price IDs)
STRIPE_BASIC_PRICE_ID=price_basic_plan_id
STRIPE_PRO_PRICE_ID=price_pro_plan_id
STRIPE_ENTERPRISE_PRICE_ID=price_enterprise_plan_id

# Container endpoints
GEMINI_CLI_URL_1=http://localhost:8001
GEMINI_CLI_URL_2=http://localhost:8002
```

## Setup Steps

### 1. Supabase Auth Setup

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to "Authentication" > "Providers"
4. Enable the providers you want to use:

#### Google OAuth Setup
1. Click on "Google" provider
2. Enable Google OAuth
3. Go to [Google Cloud Console](https://console.cloud.google.com/)
4. Create a new project or select existing one
5. Enable Google+ API and Google Identity API
6. Go to "APIs & Services" > "OAuth consent screen"
7. Choose "External" user type
8. Fill in application information:
   - Application name: "Tubby AI Agent Platform"
   - User support email: Your support email
   - Developer contact information: Your contact email
9. Add scopes: `email`, `profile`, `openid`
10. Go to "APIs & Services" > "Credentials"
11. Click "Create Credentials" > "OAuth 2.0 Client IDs"
12. Choose "Web application"
13. Add authorized redirect URIs:
    - `https://your-project.supabase.co/auth/v1/callback` (Supabase callback)
14. Copy the Client ID and Client Secret to Supabase Google provider settings

#### GitHub OAuth Setup
1. Click on "GitHub" provider
2. Enable GitHub OAuth
3. Go to [GitHub Developer Settings](https://github.com/settings/developers)
4. Click "New OAuth App"
5. Fill in application information:
   - Application name: "Tubby AI Agent Platform"
   - Homepage URL: `http://localhost:5173` (development)
   - Authorization callback URL: `https://your-project.supabase.co/auth/v1/callback`
6. Copy the Client ID and Client Secret to Supabase GitHub provider settings

### 2. Stripe Setup

1. Sign up at [Stripe](https://stripe.com)
2. Complete account verification
3. Go to Developers > API keys
4. Copy your Publishable key and Secret key
5. Go to Products in the Stripe Dashboard
6. Create subscription products:
   - Basic Plan ($9.99/month)
   - Pro Plan ($29.99/month)
   - Enterprise Plan ($99.99/month)
7. Copy the Price IDs to your `.env` file
8. Set up webhooks:
   - Go to Developers > Webhooks
   - Add endpoint: `https://yourdomain.com/stripe/webhook`
   - Select events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_failed`
   - Copy the webhook secret to your `.env` file

### 3. Database Setup

Run the updated schema in your Supabase database:

```sql
-- The schema.sql file has been updated with the users table
-- Run the entire schema.sql file in your Supabase SQL editor
```

### 4. Testing

1. Start your backend server
2. Navigate to the application
3. Click "Sign in with Google" or "Sign in with GitHub"
4. Complete OAuth flow
5. Test subscription flow with Stripe test cards:
   - Success: `4242 4242 4242 4242`
   - Decline: `4000 0000 0000 0002`

## Production Considerations

1. Use production Google OAuth credentials
2. Use production Stripe keys
3. Set up proper HTTPS
4. Configure secure session cookies
5. Set up proper CORS
6. Implement rate limiting
7. Set up monitoring and logging 