# Development Instructions: Google OAuth and Stripe Integration for Tubby

## Overview

This document provides comprehensive development instructions for integrating Google OAuth authentication and Stripe payment processing into the Tubby AI Agent Communication Platform. These integrations will enhance the platform's user management capabilities and enable monetization through subscription-based services.

## Prerequisites

Before beginning the integration process, ensure you have the following:

- Access to the Tubby repository and development environment
- Google Cloud Console account for OAuth setup
- Stripe account for payment processing
- Supabase project already configured (as mentioned in the existing .env.example)
- Basic understanding of Flask, JavaScript, and Docker

## Part 1: Google OAuth Integration

### 1.1 Google Cloud Console Setup

First, you need to create a Google Cloud project and configure OAuth credentials:

1. **Create a Google Cloud Project:**
   - Navigate to the Google Cloud Console (https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable the Google+ API and Google Identity API

2. **Configure OAuth Consent Screen:**
   - Go to "APIs & Services" > "OAuth consent screen"
   - Choose "External" user type for public applications
   - Fill in the required application information:
     - Application name: "Tubby AI Agent Platform"
     - User support email: Your support email
     - Developer contact information: Your contact email
   - Add scopes: `email`, `profile`, `openid`
   - Add test users if in development mode

3. **Create OAuth Credentials:**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client IDs"
   - Choose "Web application" as the application type
   - Add authorized redirect URIs:
     - `http://localhost:3002/auth/google/callback` (for development)
     - `https://yourdomain.com/auth/google/callback` (for production)
   - Save the Client ID and Client Secret

### 1.2 Backend Implementation

#### 1.2.1 Update Requirements

Add the following dependencies to your `backend/requirements.txt`:

```
google-auth==2.23.4
google-auth-oauthlib==1.1.0
google-auth-httplib2==0.1.1
requests==2.31.0
PyJWT==2.8.0
```

#### 1.2.2 Environment Variables

Update your `.env` file with Google OAuth credentials:

```env
# Google OAuth Configuration
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here
GOOGLE_REDIRECT_URI=http://localhost:3002/auth/google/callback

# JWT Configuration
JWT_SECRET_KEY=your_jwt_secret_key_here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
```

#### 1.2.3 OAuth Service Implementation

Create a new file `backend/services/oauth_service.py`:

```python
import os
import jwt
import requests
from datetime import datetime, timedelta
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from google_auth_oauthlib.flow import Flow

class OAuthService:
    def __init__(self):
        self.google_client_id = os.getenv('GOOGLE_CLIENT_ID')
        self.google_client_secret = os.getenv('GOOGLE_CLIENT_SECRET')
        self.google_redirect_uri = os.getenv('GOOGLE_REDIRECT_URI')
        self.jwt_secret = os.getenv('JWT_SECRET_KEY')
        self.jwt_algorithm = os.getenv('JWT_ALGORITHM', 'HS256')
        self.jwt_expiration_hours = int(os.getenv('JWT_EXPIRATION_HOURS', 24))
        
    def create_google_flow(self):
        """Create Google OAuth flow"""
        flow = Flow.from_client_config(
            {
                "web": {
                    "client_id": self.google_client_id,
                    "client_secret": self.google_client_secret,
                    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                    "token_uri": "https://oauth2.googleapis.com/token",
                    "redirect_uris": [self.google_redirect_uri]
                }
            },
            scopes=['openid', 'email', 'profile']
        )
        flow.redirect_uri = self.google_redirect_uri
        return flow
    
    def get_google_auth_url(self):
        """Generate Google OAuth authorization URL"""
        flow = self.create_google_flow()
        auth_url, _ = flow.authorization_url(prompt='consent')
        return auth_url
    
    def verify_google_token(self, code):
        """Verify Google OAuth token and return user info"""
        try:
            flow = self.create_google_flow()
            flow.fetch_token(code=code)
            
            # Get user info from Google
            credentials = flow.credentials
            user_info_response = requests.get(
                'https://www.googleapis.com/oauth2/v2/userinfo',
                headers={'Authorization': f'Bearer {credentials.token}'}
            )
            
            if user_info_response.status_code == 200:
                return user_info_response.json()
            else:
                return None
                
        except Exception as e:
            print(f"Error verifying Google token: {e}")
            return None
    
    def generate_jwt_token(self, user_data):
        """Generate JWT token for authenticated user"""
        payload = {
            'user_id': user_data.get('id'),
            'email': user_data.get('email'),
            'name': user_data.get('name'),
            'picture': user_data.get('picture'),
            'exp': datetime.utcnow() + timedelta(hours=self.jwt_expiration_hours),
            'iat': datetime.utcnow()
        }
        
        token = jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)
        return token
    
    def verify_jwt_token(self, token):
        """Verify JWT token and return user data"""
        try:
            payload = jwt.decode(token, self.jwt_secret, algorithms=[self.jwt_algorithm])
            return payload
        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None
```

#### 1.2.4 User Management with Supabase

Create `backend/services/user_service.py` to handle user data with Supabase:

```python
import os
from supabase import create_client, Client

class UserService:
    def __init__(self):
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_ANON_KEY')
        self.supabase: Client = create_client(supabase_url, supabase_key)
    
    def create_or_update_user(self, google_user_data):
        """Create or update user in Supabase"""
        try:
            user_data = {
                'google_id': google_user_data.get('id'),
                'email': google_user_data.get('email'),
                'name': google_user_data.get('name'),
                'picture': google_user_data.get('picture'),
                'verified_email': google_user_data.get('verified_email', False)
            }
            
            # Check if user exists
            existing_user = self.supabase.table('users').select('*').eq('google_id', user_data['google_id']).execute()
            
            if existing_user.data:
                # Update existing user
                result = self.supabase.table('users').update(user_data).eq('google_id', user_data['google_id']).execute()
                return result.data[0] if result.data else None
            else:
                # Create new user
                result = self.supabase.table('users').insert(user_data).execute()
                return result.data[0] if result.data else None
                
        except Exception as e:
            print(f"Error managing user: {e}")
            return None
    
    def get_user_by_id(self, user_id):
        """Get user by ID"""
        try:
            result = self.supabase.table('users').select('*').eq('id', user_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting user: {e}")
            return None
    
    def get_user_by_google_id(self, google_id):
        """Get user by Google ID"""
        try:
            result = self.supabase.table('users').select('*').eq('google_id', google_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting user by Google ID: {e}")
            return None
```

#### 1.2.5 Authentication Routes

Update your main Flask application (`backend/app.py` or `main.py`) to include authentication routes:

```python
from flask import Flask, request, jsonify, redirect, session
from services.oauth_service import OAuthService
from services.user_service import UserService
import os

app = Flask(__name__)
app.secret_key = os.getenv('JWT_SECRET_KEY', 'your-secret-key')

oauth_service = OAuthService()
user_service = UserService()

@app.route('/auth/google')
def google_auth():
    """Initiate Google OAuth flow"""
    auth_url = oauth_service.get_google_auth_url()
    return redirect(auth_url)

@app.route('/auth/google/callback')
def google_callback():
    """Handle Google OAuth callback"""
    code = request.args.get('code')
    if not code:
        return jsonify({'error': 'Authorization code not provided'}), 400
    
    # Verify Google token and get user info
    google_user_data = oauth_service.verify_google_token(code)
    if not google_user_data:
        return jsonify({'error': 'Failed to verify Google token'}), 400
    
    # Create or update user in database
    user = user_service.create_or_update_user(google_user_data)
    if not user:
        return jsonify({'error': 'Failed to create user'}), 500
    
    # Generate JWT token
    jwt_token = oauth_service.generate_jwt_token(google_user_data)
    
    # Store token in session or return to frontend
    session['jwt_token'] = jwt_token
    session['user'] = user
    
    # Redirect to frontend with success
    return redirect('/?auth=success')

@app.route('/auth/logout')
def logout():
    """Logout user"""
    session.clear()
    return jsonify({'message': 'Logged out successfully'})

@app.route('/auth/user')
def get_current_user():
    """Get current authenticated user"""
    jwt_token = session.get('jwt_token') or request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not jwt_token:
        return jsonify({'error': 'No token provided'}), 401
    
    user_data = oauth_service.verify_jwt_token(jwt_token)
    if not user_data:
        return jsonify({'error': 'Invalid or expired token'}), 401
    
    return jsonify({'user': user_data})

# Middleware for protected routes
def require_auth(f):
    """Decorator to require authentication"""
    def decorated_function(*args, **kwargs):
        jwt_token = session.get('jwt_token') or request.headers.get('Authorization', '').replace('Bearer ', '')
        
        if not jwt_token:
            return jsonify({'error': 'Authentication required'}), 401
        
        user_data = oauth_service.verify_jwt_token(jwt_token)
        if not user_data:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        request.current_user = user_data
        return f(*args, **kwargs)
    
    decorated_function.__name__ = f.__name__
    return decorated_function
```

### 1.3 Frontend Implementation

#### 1.3.1 Update HTML Template

Update your `backend/templates/index.html` to include Google OAuth functionality:

```html
<!-- Add this to your existing HTML -->
<div id="auth-section" class="auth-section">
    <div id="login-form" class="login-form" style="display: none;">
        <h3>Sign in to Tubby</h3>
        <button id="google-signin-btn" class="google-signin-btn">
            <img src="https://developers.google.com/identity/images/g-logo.png" alt="Google" width="20" height="20">
            Sign in with Google
        </button>
    </div>
    
    <div id="user-profile" class="user-profile" style="display: none;">
        <img id="user-avatar" class="user-avatar" src="" alt="User Avatar">
        <span id="user-name"></span>
        <button id="logout-btn" class="logout-btn">Logout</button>
    </div>
</div>
```

#### 1.3.2 JavaScript Authentication Logic

Add this JavaScript to handle authentication:

```javascript
// Authentication management
class AuthManager {
    constructor() {
        this.currentUser = null;
        this.init();
    }
    
    async init() {
        await this.checkAuthStatus();
        this.setupEventListeners();
    }
    
    async checkAuthStatus() {
        try {
            const response = await fetch('/auth/user');
            if (response.ok) {
                const data = await response.json();
                this.currentUser = data.user;
                this.showUserProfile();
            } else {
                this.showLoginForm();
            }
        } catch (error) {
            console.error('Error checking auth status:', error);
            this.showLoginForm();
        }
    }
    
    setupEventListeners() {
        const googleSigninBtn = document.getElementById('google-signin-btn');
        const logoutBtn = document.getElementById('logout-btn');
        
        if (googleSigninBtn) {
            googleSigninBtn.addEventListener('click', () => {
                window.location.href = '/auth/google';
            });
        }
        
        if (logoutBtn) {
            logoutBtn.addEventListener('click', async () => {
                await this.logout();
            });
        }
    }
    
    showLoginForm() {
        document.getElementById('login-form').style.display = 'block';
        document.getElementById('user-profile').style.display = 'none';
    }
    
    showUserProfile() {
        if (this.currentUser) {
            document.getElementById('user-avatar').src = this.currentUser.picture || '';
            document.getElementById('user-name').textContent = this.currentUser.name || this.currentUser.email;
            document.getElementById('login-form').style.display = 'none';
            document.getElementById('user-profile').style.display = 'block';
        }
    }
    
    async logout() {
        try {
            await fetch('/auth/logout');
            this.currentUser = null;
            this.showLoginForm();
            // Optionally reload the page
            window.location.reload();
        } catch (error) {
            console.error('Error logging out:', error);
        }
    }
    
    isAuthenticated() {
        return this.currentUser !== null;
    }
    
    getUser() {
        return this.currentUser;
    }
}

// Initialize authentication
const authManager = new AuthManager();

// Check for auth success parameter
const urlParams = new URLSearchParams(window.location.search);
if (urlParams.get('auth') === 'success') {
    // Remove the parameter from URL
    window.history.replaceState({}, document.title, window.location.pathname);
    // Refresh auth status
    authManager.checkAuthStatus();
}
```

### 1.4 Database Schema

Create the following table in your Supabase database:

```sql
-- Users table
CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    google_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    picture TEXT,
    verified_email BOOLEAN DEFAULT FALSE,
    subscription_status VARCHAR(50) DEFAULT 'free',
    subscription_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_users_google_id ON users(google_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_subscription_status ON users(subscription_status);

-- Update trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Part 2: Stripe Integration

### 2.1 Stripe Account Setup

1. **Create Stripe Account:**
   - Sign up at https://stripe.com
   - Complete account verification
   - Navigate to the Dashboard

2. **Get API Keys:**
   - Go to Developers > API keys
   - Copy your Publishable key and Secret key
   - For testing, use the test keys

3. **Create Products and Prices:**
   - Go to Products in the Stripe Dashboard
   - Create subscription products (e.g., "Tubby Pro", "Tubby Enterprise")
   - Set up recurring prices for each product

### 2.2 Backend Stripe Integration

#### 2.2.1 Update Requirements

Add Stripe to your `backend/requirements.txt`:

```
stripe==7.8.0
```

#### 2.2.2 Environment Variables

Add Stripe configuration to your `.env` file:

```env
# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Subscription Plans
STRIPE_BASIC_PRICE_ID=price_basic_plan_id
STRIPE_PRO_PRICE_ID=price_pro_plan_id
STRIPE_ENTERPRISE_PRICE_ID=price_enterprise_plan_id
```

#### 2.2.3 Stripe Service Implementation

Create `backend/services/stripe_service.py`:

```python
import os
import stripe
from services.user_service import UserService

class StripeService:
    def __init__(self):
        stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
        self.webhook_secret = os.getenv('STRIPE_WEBHOOK_SECRET')
        self.user_service = UserService()
        
        # Price IDs for different plans
        self.price_ids = {
            'basic': os.getenv('STRIPE_BASIC_PRICE_ID'),
            'pro': os.getenv('STRIPE_PRO_PRICE_ID'),
            'enterprise': os.getenv('STRIPE_ENTERPRISE_PRICE_ID')
        }
    
    def create_customer(self, user_data):
        """Create a Stripe customer"""
        try:
            customer = stripe.Customer.create(
                email=user_data.get('email'),
                name=user_data.get('name'),
                metadata={
                    'user_id': user_data.get('id'),
                    'google_id': user_data.get('google_id')
                }
            )
            return customer
        except Exception as e:
            print(f"Error creating Stripe customer: {e}")
            return None
    
    def create_checkout_session(self, user_id, plan_type, success_url, cancel_url):
        """Create a Stripe checkout session for subscription"""
        try:
            # Get user data
            user = self.user_service.get_user_by_id(user_id)
            if not user:
                return None
            
            # Get or create Stripe customer
            customer = self.get_or_create_customer(user)
            if not customer:
                return None
            
            # Get price ID for the plan
            price_id = self.price_ids.get(plan_type)
            if not price_id:
                return None
            
            # Create checkout session
            session = stripe.checkout.Session.create(
                customer=customer.id,
                payment_method_types=['card'],
                line_items=[{
                    'price': price_id,
                    'quantity': 1,
                }],
                mode='subscription',
                success_url=success_url,
                cancel_url=cancel_url,
                metadata={
                    'user_id': user_id,
                    'plan_type': plan_type
                }
            )
            
            return session
            
        except Exception as e:
            print(f"Error creating checkout session: {e}")
            return None
    
    def get_or_create_customer(self, user_data):
        """Get existing Stripe customer or create new one"""
        try:
            # Try to find existing customer by email
            customers = stripe.Customer.list(email=user_data.get('email'), limit=1)
            
            if customers.data:
                return customers.data[0]
            else:
                return self.create_customer(user_data)
                
        except Exception as e:
            print(f"Error getting/creating customer: {e}")
            return None
    
    def get_subscription_status(self, customer_id):
        """Get customer's subscription status"""
        try:
            subscriptions = stripe.Subscription.list(customer=customer_id, status='active', limit=1)
            
            if subscriptions.data:
                subscription = subscriptions.data[0]
                return {
                    'status': subscription.status,
                    'plan': subscription.items.data[0].price.nickname or 'Unknown',
                    'current_period_end': subscription.current_period_end,
                    'cancel_at_period_end': subscription.cancel_at_period_end
                }
            else:
                return {'status': 'inactive'}
                
        except Exception as e:
            print(f"Error getting subscription status: {e}")
            return {'status': 'error'}
    
    def cancel_subscription(self, subscription_id):
        """Cancel a subscription"""
        try:
            subscription = stripe.Subscription.modify(
                subscription_id,
                cancel_at_period_end=True
            )
            return subscription
        except Exception as e:
            print(f"Error canceling subscription: {e}")
            return None
    
    def handle_webhook(self, payload, sig_header):
        """Handle Stripe webhook events"""
        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, self.webhook_secret
            )
            
            # Handle different event types
            if event['type'] == 'checkout.session.completed':
                self.handle_checkout_completed(event['data']['object'])
            elif event['type'] == 'customer.subscription.updated':
                self.handle_subscription_updated(event['data']['object'])
            elif event['type'] == 'customer.subscription.deleted':
                self.handle_subscription_deleted(event['data']['object'])
            elif event['type'] == 'invoice.payment_failed':
                self.handle_payment_failed(event['data']['object'])
            
            return True
            
        except ValueError as e:
            print(f"Invalid payload: {e}")
            return False
        except stripe.error.SignatureVerificationError as e:
            print(f"Invalid signature: {e}")
            return False
    
    def handle_checkout_completed(self, session):
        """Handle successful checkout completion"""
        try:
            user_id = session.get('metadata', {}).get('user_id')
            plan_type = session.get('metadata', {}).get('plan_type')
            
            if user_id:
                # Update user subscription status in database
                self.user_service.supabase.table('users').update({
                    'subscription_status': plan_type,
                    'subscription_id': session.get('subscription')
                }).eq('id', user_id).execute()
                
        except Exception as e:
            print(f"Error handling checkout completion: {e}")
    
    def handle_subscription_updated(self, subscription):
        """Handle subscription updates"""
        try:
            customer_id = subscription.get('customer')
            status = subscription.get('status')
            
            # Find user by customer ID and update status
            # This requires storing customer_id in user table
            
        except Exception as e:
            print(f"Error handling subscription update: {e}")
    
    def handle_subscription_deleted(self, subscription):
        """Handle subscription cancellation"""
        try:
            customer_id = subscription.get('customer')
            
            # Update user to free plan
            # This requires storing customer_id in user table
            
        except Exception as e:
            print(f"Error handling subscription deletion: {e}")
    
    def handle_payment_failed(self, invoice):
        """Handle failed payments"""
        try:
            customer_id = invoice.get('customer')
            
            # Notify user of payment failure
            # Optionally downgrade to free plan after grace period
            
        except Exception as e:
            print(f"Error handling payment failure: {e}")
```

#### 2.2.4 Stripe Routes

Add these routes to your Flask application:

```python
from services.stripe_service import StripeService

stripe_service = StripeService()

@app.route('/stripe/create-checkout-session', methods=['POST'])
@require_auth
def create_checkout_session():
    """Create Stripe checkout session"""
    data = request.get_json()
    plan_type = data.get('plan_type')
    
    if not plan_type or plan_type not in ['basic', 'pro', 'enterprise']:
        return jsonify({'error': 'Invalid plan type'}), 400
    
    user_id = request.current_user.get('user_id')
    success_url = request.url_root + 'subscription/success'
    cancel_url = request.url_root + 'subscription/cancel'
    
    session = stripe_service.create_checkout_session(
        user_id, plan_type, success_url, cancel_url
    )
    
    if session:
        return jsonify({'checkout_url': session.url})
    else:
        return jsonify({'error': 'Failed to create checkout session'}), 500

@app.route('/stripe/subscription-status')
@require_auth
def get_subscription_status():
    """Get user's subscription status"""
    user_id = request.current_user.get('user_id')
    user = user_service.get_user_by_id(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    # Get Stripe customer
    customer = stripe_service.get_or_create_customer(user)
    if customer:
        status = stripe_service.get_subscription_status(customer.id)
        return jsonify(status)
    else:
        return jsonify({'status': 'inactive'})

@app.route('/stripe/cancel-subscription', methods=['POST'])
@require_auth
def cancel_subscription():
    """Cancel user's subscription"""
    user_id = request.current_user.get('user_id')
    user = user_service.get_user_by_id(user_id)
    
    if not user or not user.get('subscription_id'):
        return jsonify({'error': 'No active subscription found'}), 404
    
    result = stripe_service.cancel_subscription(user['subscription_id'])
    
    if result:
        return jsonify({'message': 'Subscription canceled successfully'})
    else:
        return jsonify({'error': 'Failed to cancel subscription'}), 500

@app.route('/stripe/webhook', methods=['POST'])
def stripe_webhook():
    """Handle Stripe webhooks"""
    payload = request.get_data()
    sig_header = request.headers.get('Stripe-Signature')
    
    if stripe_service.handle_webhook(payload, sig_header):
        return jsonify({'status': 'success'})
    else:
        return jsonify({'error': 'Webhook handling failed'}), 400

@app.route('/subscription/success')
def subscription_success():
    """Subscription success page"""
    return """
    <html>
        <head><title>Subscription Successful</title></head>
        <body>
            <h1>Welcome to Tubby Pro!</h1>
            <p>Your subscription has been activated successfully.</p>
            <a href="/">Return to Dashboard</a>
        </body>
    </html>
    """

@app.route('/subscription/cancel')
def subscription_cancel():
    """Subscription canceled page"""
    return """
    <html>
        <head><title>Subscription Canceled</title></head>
        <body>
            <h1>Subscription Canceled</h1>
            <p>You can try again anytime.</p>
            <a href="/">Return to Dashboard</a>
        </body>
    </html>
    """
```

### 2.3 Frontend Stripe Integration

#### 2.3.1 Add Stripe.js

Add Stripe.js to your HTML template:

```html
<script src="https://js.stripe.com/v3/"></script>
```

#### 2.3.2 Subscription Management UI

Add subscription management to your HTML:

```html
<div id="subscription-section" class="subscription-section" style="display: none;">
    <h3>Subscription Plans</h3>
    
    <div class="plans-container">
        <div class="plan-card">
            <h4>Basic Plan</h4>
            <p class="price">$9.99/month</p>
            <ul>
                <li>Basic AI agent access</li>
                <li>Limited terminal sessions</li>
                <li>Community support</li>
            </ul>
            <button class="subscribe-btn" data-plan="basic">Subscribe</button>
        </div>
        
        <div class="plan-card featured">
            <h4>Pro Plan</h4>
            <p class="price">$29.99/month</p>
            <ul>
                <li>Full AI agent access</li>
                <li>Unlimited terminal sessions</li>
                <li>Priority support</li>
                <li>Advanced features</li>
            </ul>
            <button class="subscribe-btn" data-plan="pro">Subscribe</button>
        </div>
        
        <div class="plan-card">
            <h4>Enterprise Plan</h4>
            <p class="price">$99.99/month</p>
            <ul>
                <li>Everything in Pro</li>
                <li>Custom integrations</li>
                <li>Dedicated support</li>
                <li>SLA guarantee</li>
            </ul>
            <button class="subscribe-btn" data-plan="enterprise">Subscribe</button>
        </div>
    </div>
    
    <div id="current-subscription" class="current-subscription" style="display: none;">
        <h4>Current Subscription</h4>
        <p id="subscription-details"></p>
        <button id="cancel-subscription-btn" class="cancel-btn">Cancel Subscription</button>
    </div>
</div>
```

#### 2.3.3 JavaScript Subscription Logic

Add JavaScript for subscription management:

```javascript
// Subscription management
class SubscriptionManager {
    constructor() {
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.loadSubscriptionStatus();
    }
    
    setupEventListeners() {
        // Subscribe buttons
        document.querySelectorAll('.subscribe-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const planType = e.target.getAttribute('data-plan');
                this.subscribeToPlan(planType);
            });
        });
        
        // Cancel subscription button
        const cancelBtn = document.getElementById('cancel-subscription-btn');
        if (cancelBtn) {
            cancelBtn.addEventListener('click', () => {
                this.cancelSubscription();
            });
        }
    }
    
    async subscribeToPlan(planType) {
        if (!authManager.isAuthenticated()) {
            alert('Please sign in to subscribe');
            return;
        }
        
        try {
            const response = await fetch('/stripe/create-checkout-session', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ plan_type: planType })
            });
            
            const data = await response.json();
            
            if (response.ok && data.checkout_url) {
                window.location.href = data.checkout_url;
            } else {
                alert('Error creating checkout session: ' + (data.error || 'Unknown error'));
            }
        } catch (error) {
            console.error('Error subscribing:', error);
            alert('Error subscribing to plan');
        }
    }
    
    async loadSubscriptionStatus() {
        if (!authManager.isAuthenticated()) {
            return;
        }
        
        try {
            const response = await fetch('/stripe/subscription-status');
            const data = await response.json();
            
            if (response.ok) {
                this.displaySubscriptionStatus(data);
            }
        } catch (error) {
            console.error('Error loading subscription status:', error);
        }
    }
    
    displaySubscriptionStatus(status) {
        const currentSubDiv = document.getElementById('current-subscription');
        const detailsP = document.getElementById('subscription-details');
        
        if (status.status === 'active') {
            detailsP.textContent = `Active ${status.plan} subscription`;
            currentSubDiv.style.display = 'block';
        } else {
            currentSubDiv.style.display = 'none';
        }
    }
    
    async cancelSubscription() {
        if (!confirm('Are you sure you want to cancel your subscription?')) {
            return;
        }
        
        try {
            const response = await fetch('/stripe/cancel-subscription', {
                method: 'POST'
            });
            
            const data = await response.json();
            
            if (response.ok) {
                alert('Subscription canceled successfully');
                this.loadSubscriptionStatus();
            } else {
                alert('Error canceling subscription: ' + (data.error || 'Unknown error'));
            }
        } catch (error) {
            console.error('Error canceling subscription:', error);
            alert('Error canceling subscription');
        }
    }
}

// Initialize subscription manager
const subscriptionManager = new SubscriptionManager();

// Show subscription section for authenticated users
if (authManager.isAuthenticated()) {
    document.getElementById('subscription-section').style.display = 'block';
}
```

### 2.4 Update Database Schema

Add subscription-related fields to your users table:

```sql
-- Add subscription fields to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_customer_id VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_plan VARCHAR(50) DEFAULT 'free';
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_period_end TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_cancel_at_period_end BOOLEAN DEFAULT FALSE;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_stripe_customer_id ON users(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_users_subscription_plan ON users(subscription_plan);
```

## Part 3: Integration Testing

### 3.1 Testing Google OAuth

1. **Test Authentication Flow:**
   - Start your application
   - Click "Sign in with Google"
   - Complete OAuth flow
   - Verify user data is stored in Supabase
   - Test logout functionality

2. **Test JWT Token Handling:**
   - Verify tokens are generated correctly
   - Test token expiration
   - Test protected routes

### 3.2 Testing Stripe Integration

1. **Test Subscription Flow:**
   - Sign in with Google
   - Select a subscription plan
   - Complete checkout with test card (4242 4242 4242 4242)
   - Verify subscription status updates

2. **Test Webhook Handling:**
   - Use Stripe CLI to forward webhooks to localhost
   - Test various webhook events
   - Verify database updates

### 3.3 End-to-End Testing

Create a comprehensive test script to verify the entire integration:

```python
# test_integration.py
import requests
import time

def test_oauth_integration():
    """Test Google OAuth integration"""
    # This would require manual testing due to OAuth flow
    print("Manual testing required for OAuth flow")

def test_stripe_integration():
    """Test Stripe integration"""
    # Test creating checkout session (requires authentication)
    print("Testing Stripe integration...")
    
    # Add your test cases here
    pass

if __name__ == "__main__":
    test_oauth_integration()
    test_stripe_integration()
```

## Part 4: Deployment Considerations

### 4.1 Environment Variables for Production

Ensure all production environment variables are set:

```env
# Production Google OAuth
GOOGLE_CLIENT_ID=your_production_client_id
GOOGLE_CLIENT_SECRET=your_production_client_secret
GOOGLE_REDIRECT_URI=https://yourdomain.com/auth/google/callback

# Production Stripe
STRIPE_PUBLISHABLE_KEY=pk_live_your_live_publishable_key
STRIPE_SECRET_KEY=sk_live_your_live_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_live_webhook_secret

# Production JWT
JWT_SECRET_KEY=your_very_secure_production_secret

# Production Supabase
SUPABASE_URL=your_production_supabase_url
SUPABASE_ANON_KEY=your_production_supabase_key
```

### 4.2 Security Considerations

1. **HTTPS Only:** Ensure all production traffic uses HTTPS
2. **Secure Cookies:** Set secure flags on session cookies
3. **CORS Configuration:** Properly configure CORS for your domain
4. **Rate Limiting:** Implement rate limiting on authentication endpoints
5. **Input Validation:** Validate all user inputs
6. **Error Handling:** Don't expose sensitive information in error messages

### 4.3 Monitoring and Logging

Implement proper logging for:
- Authentication attempts
- Subscription events
- Payment failures
- API errors
- User activities

## Conclusion

This integration adds robust user authentication and payment processing to the Tubby platform. The Google OAuth integration provides a seamless sign-in experience, while Stripe enables flexible subscription management. Both integrations work together with the existing Supabase infrastructure to create a complete user management and monetization system.

Remember to thoroughly test all functionality in a development environment before deploying to production, and ensure all security best practices are followed.

