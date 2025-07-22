from flask import Flask, render_template, request, jsonify, redirect, session
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import requests
import os
import re
import json
import redis
import time
from datetime import datetime
from dotenv import load_dotenv
import tempfile
import subprocess
from supabase_client import supabase_manager
from services.oauth_service import OAuthService
from services.user_service import UserService
from services.stripe_service import StripeService

# Load .env from parent directory (project root)
try:
    load_dotenv('../.env')
except Exception:
    pass  # Use defaults if .env file doesn't exist or can't be loaded

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
app.config['SESSION_COOKIE_SECURE'] = False  # Set to True in production with HTTPS

# Configure CORS
CORS(app, origins=['http://localhost:3001', 'http://localhost:3003', 'http://localhost:3010', 'http://localhost:3015', 'http://localhost:4173'], 
     supports_credentials=True, methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])

socketio = SocketIO(app, cors_allowed_origins="*")

# Redis connection
redis_client = redis.Redis(host='redis', port=6379, decode_responses=True)

# Container endpoints
# Use environment variable override so local dev can hit localhost
GEMINI_CLI_URL_1 = os.getenv('GEMINI_CLI_URL_1', 'http://localhost:8001')
GEMINI_CLI_URL_2 = os.getenv('GEMINI_CLI_URL_2', 'http://localhost:8002')

# Initialize authentication services
oauth_service = OAuthService()
user_service = UserService()
stripe_service = StripeService()

# Authentication decorator
def require_auth(f):
    """Decorator to require authentication - CRITICAL FIX FOR AUTH BUG"""
    def decorated_function(*args, **kwargs):
        # Check for guest user first
        if session.get('is_guest') and session.get('guest_user'):
            request.current_user = session['guest_user']
            return f(*args, **kwargs)
        
        access_token = session.get('access_token') or request.headers.get('Authorization', '').replace('Bearer ', '')
        
        if not access_token:
            return jsonify({'error': 'Authentication required'}), 401
        
        user_data = oauth_service.verify_supabase_token(access_token)
        if not user_data:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # CRITICAL FIX: Look up user in database by Supabase ID
        supabase_id = user_data.get('id')
        if not supabase_id:
            return jsonify({'error': 'Invalid user data'}), 401
        
        # Try to find user in database
        user = user_service.get_user_by_supabase_id(supabase_id)
        
        if not user:
            # Create user if not found - CRITICAL FIX
            print(f"User not found in database, creating new user: {user_data.get('email', 'Unknown')}")
            user = user_service.create_user_from_oauth(user_data)
            
            if not user:
                return jsonify({'error': 'Failed to create user account'}), 500
        
        # Set the database user record as current user
        request.current_user = user
        return f(*args, **kwargs)
    
    decorated_function.__name__ = f.__name__
    return decorated_function

# API Key Management Endpoints
@app.route('/api/user/api-keys', methods=['POST'])
@require_auth
def save_api_key():
    """Save encrypted API key for a user"""
    try:
        data = request.get_json()
        user_id = request.current_user.get('id')
        service = data.get('service')  # 'gemini', 'anthropic', 'openai'
        api_key = data.get('api_key')
        
        if not all([service, api_key]):
            return jsonify({'error': 'Missing service or api_key'}), 400
        
        # For guest users, don't actually save to database
        if request.current_user.get('provider') == 'guest':
            return jsonify({'success': True, 'message': f'{service} API key saved for this session (guest user)'})
        
        success = supabase_manager.save_api_key(user_id, service, api_key)
        
        if success:
            return jsonify({'success': True, 'message': f'{service} API key saved successfully'})
        else:
            return jsonify({'error': 'Failed to save API key'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/user/api-keys/<service>', methods=['GET'])
@require_auth
def get_api_key(service):
    """Get decrypted API key for a user and service"""
    try:
        user_id = request.current_user.get('id')
        
        # For guest users, return false since they don't have saved keys
        if request.current_user.get('provider') == 'guest':
            return jsonify({'success': True, 'service': service, 'has_key': False})
        
        api_key = supabase_manager.get_api_key(user_id, service)
        
        if api_key:
            return jsonify({'success': True, 'service': service, 'has_key': True})
        else:
            return jsonify({'success': True, 'service': service, 'has_key': False})
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/user/api-keys', methods=['GET'])
@require_auth
def list_api_keys():
    """List all API keys for a user"""
    try:
        user_id = request.current_user.get('id')
        
        # For guest users, return empty list since they don't have saved keys
        if request.current_user.get('provider') == 'guest':
            return jsonify({'success': True, 'api_keys': []})
        
        api_keys = supabase_manager.list_user_api_keys(user_id)
        
        return jsonify({'success': True, 'api_keys': api_keys})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/user/api-keys/<service>', methods=['DELETE'])
@require_auth
def delete_api_key(service):
    """Delete API key for a user and service"""
    try:
        user_id = request.current_user.get('id')
        
        # For guest users, return success since they don't have saved keys
        if request.current_user.get('provider') == 'guest':
            return jsonify({'success': True, 'message': f'{service} API key deleted (guest user)'})
        
        success = supabase_manager.delete_api_key(user_id, service)
        
        if success:
            return jsonify({'success': True, 'message': f'{service} API key deleted successfully'})
        else:
            return jsonify({'error': 'Failed to delete API key'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# OAuth Routes
@app.route('/auth/google')
def google_auth():
    """Initiate Google OAuth flow"""
    try:
        auth_url = oauth_service.get_supabase_auth_url('google')
        if auth_url:
            return redirect(auth_url)
        else:
            return f"""
            <html>
            <head><title>OAuth Not Configured</title></head>
            <body style="background: black; color: white; font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0;">
                <div style="text-align: center; padding: 2rem; border: 1px solid #333; border-radius: 8px;">
                    <h1>🔧 Google OAuth Not Configured</h1>
                    <p>Google OAuth is not configured in Supabase yet. Please:</p>
                    <ol style="text-align: left; display: inline-block;">
                        <li>Go to Supabase Dashboard → Authentication → Providers</li>
                        <li>Enable Google provider</li>
                        <li>Add your Google OAuth credentials</li>
                        <li>Or use "Continue as Guest" for now</li>
                    </ol>
                    <br><br>
                    <a href="http://localhost:3007" style="color: #3b82f6; text-decoration: none;">← Back to Login</a>
                </div>
            </body>
            </html>
            """, 200
    except Exception as e:
        return f"""
        <html>
        <head><title>OAuth Error</title></head>
        <body style="background: black; color: white; font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0;">
            <div style="text-align: center; padding: 2rem; border: 1px solid #333; border-radius: 8px;">
                <h1>⚠️ OAuth Configuration Error</h1>
                <p>There was an error configuring OAuth: {str(e)}</p>
                <br><br>
                <a href="http://localhost:3007" style="color: #3b82f6; text-decoration: none;">← Back to Login</a>
            </div>
        </body>
        </html>
        """, 200

@app.route('/auth/github')
def github_auth():
    """Initiate GitHub OAuth flow"""
    try:
        auth_url = oauth_service.get_supabase_auth_url('github')
        if auth_url:
            return redirect(auth_url)
        else:
            return f"""
            <html>
            <head><title>OAuth Not Configured</title></head>
            <body style="background: black; color: white; font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0;">
                <div style="text-align: center; padding: 2rem; border: 1px solid #333; border-radius: 8px;">
                    <h1>🔧 GitHub OAuth Not Configured</h1>
                    <p>GitHub OAuth is not configured in Supabase yet. Please:</p>
                    <ol style="text-align: left; display: inline-block;">
                        <li>Go to Supabase Dashboard → Authentication → Providers</li>
                        <li>Enable GitHub provider</li>
                        <li>Add your GitHub OAuth credentials</li>
                        <li>Or use "Continue as Guest" for now</li>
                    </ol>
                    <br><br>
                    <a href="http://localhost:3007" style="color: #3b82f6; text-decoration: none;">← Back to Login</a>
                </div>
            </body>
            </html>
            """, 200
    except Exception as e:
        return f"""
        <html>
        <head><title>OAuth Error</title></head>
        <body style="background: black; color: white; font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0;">
            <div style="text-align: center; padding: 2rem; border: 1px solid #333; border-radius: 8px;">
                <h1>⚠️ OAuth Configuration Error</h1>
                <p>There was an error configuring OAuth: {str(e)}</p>
                <br><br>
                <a href="http://localhost:3007" style="color: #3b82f6; text-decoration: none;">← Back to Login</a>
            </div>
        </body>
        </html>
        """, 200

@app.route('/auth/guest', methods=['GET', 'POST'])
def guest_auth():
    """Handle guest authentication"""
    # Create a guest user session
    guest_user = {
        'id': f'guest_{int(time.time())}',
        'email': 'guest@tubby.ai',
        'name': 'Guest User',
        'picture': None,
        'provider': 'guest',
        'verified_email': False
    }
    
    # Store guest user in session
    session['guest_user'] = guest_user
    session['is_guest'] = True
    
    return jsonify({'user': guest_user, 'message': 'Guest session created'})

@app.route('/auth/callback')
def auth_callback():
    """Handle OAuth callback from Supabase"""
    # Check for token in query parameters first (for direct API calls)
    access_token = request.args.get('access_token')
    refresh_token = request.args.get('refresh_token')
    
    # If no token in query params, this is likely a browser redirect with fragment
    # Return a page that will extract the token from the fragment and send it to us
    if not access_token:
        frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3001')
        return f'''
        <!DOCTYPE html>
        <html>
        <head>
            <title>Processing Authentication...</title>
        </head>
        <body>
            <div style="text-align: center; margin-top: 50px;">
                <h2>Processing your authentication...</h2>
                <p>Please wait while we complete your sign-in.</p>
            </div>
            <script>
                // Extract token from URL fragment
                const hash = window.location.hash.substring(1);
                const params = new URLSearchParams(hash);
                const access_token = params.get('access_token');
                const refresh_token = params.get('refresh_token');
                
                if (access_token) {{
                    // Send token to backend via POST
                    fetch('http://localhost:5004/auth/callback', {{
                        method: 'POST',
                        headers: {{
                            'Content-Type': 'application/json',
                        }},
                        credentials: 'include',
                        body: JSON.stringify({{
                            access_token: access_token,
                            refresh_token: refresh_token
                        }})
                    }})
                    .then(response => response.json())
                    .then(data => {{
                        if (data.success) {{
                            // Redirect to frontend with success
                            window.location.href = window.location.origin + '/?auth=success';
                        }} else {{
                            alert('Authentication failed: ' + (data.error || 'Unknown error'));
                        }}
                    }})
                    .catch(error => {{
                        console.error('Error:', error);
                        alert('Authentication failed. Please try again.');
                    }});
                }} else {{
                    alert('No access token found in URL');
                }}
            </script>
        </body>
        </html>
        '''
    
    # Verify token and get user data from Supabase
    user_data = oauth_service.verify_supabase_token(access_token)
    if not user_data:
        return jsonify({'error': 'Failed to verify token'}), 400
    
    # Create or update user in our database
    user = user_service.create_or_update_user_from_supabase(user_data)
    if not user:
        return jsonify({'error': 'Failed to create user'}), 500
    
    # Store tokens in session
    session['access_token'] = access_token
    session['refresh_token'] = refresh_token
    session['user'] = user
    
    # Redirect to frontend with success
    frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3001')
    return redirect(f'{frontend_url}/?auth=success')

@app.route('/auth/callback', methods=['POST'])
def auth_callback_post():
    """Handle OAuth callback token from JavaScript"""
    try:
        data = request.get_json()
        access_token = data.get('access_token')
        refresh_token = data.get('refresh_token')
        
        print(f"Received auth callback with access_token: {access_token[:20] if access_token else 'None'}...")
        
        if not access_token:
            return jsonify({'error': 'Access token not provided'}), 400
        
        # Verify token and get user data from Supabase
        print("Verifying Supabase token...")
        user_data = oauth_service.verify_supabase_token(access_token)
        if not user_data:
            print("Failed to verify Supabase token")
            return jsonify({'error': 'Failed to verify token'}), 400
        
        print(f"Token verified, user data: {user_data}")
        
        # Create or update user in our database
        print("Creating/updating user in database...")
        user = user_service.create_or_update_user_from_supabase(user_data)
        if not user:
            print("Failed to create/update user in database")
            return jsonify({'error': 'Failed to create user'}), 500
        
        print(f"User created/updated successfully: {user}")
        
        # Store tokens in session
        session['access_token'] = access_token
        session['refresh_token'] = refresh_token
        session['user'] = user
        
        return jsonify({'success': True, 'message': 'Authentication successful'})
        
    except Exception as e:
        print(f"Error in auth_callback_post: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Internal server error: {str(e)}'}), 500

@app.route('/auth/google/callback')
def google_callback():
    """Legacy Google OAuth callback - redirects to new callback"""
    return redirect('/auth/callback?' + request.query_string.decode())

@app.route('/auth/logout')
def logout():
    """Logout user"""
    session.clear()
    return jsonify({'message': 'Logged out successfully'})

@app.route('/auth/user')
def get_current_user():
    """Get current authenticated user"""
    print(f"Auth user request - Session: {dict(session)}")
    print(f"Headers: {dict(request.headers)}")
    
    # Check for guest user first
    if session.get('is_guest') and session.get('guest_user'):
        print("Returning guest user")
        return jsonify({'user': session['guest_user']})
    
    access_token = session.get('access_token') or request.headers.get('Authorization', '').replace('Bearer ', '')
    
    print(f"Access token: {access_token[:20] if access_token else 'None'}...")
    
    if not access_token:
        print("No access token found")
        return jsonify({'error': 'No token provided'}), 401
    
    try:
        user_data = oauth_service.verify_supabase_token(access_token)
        if not user_data:
            # Fallback to session-stored user if available
            if session.get('user'):
                return jsonify({'user': session['user']})
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        print(f"User data verified: {user_data}")
        return jsonify({'user': user_data})
    except Exception as e:
        print(f"Error in get_current_user: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Server error: {str(e)}'}), 500

# Stripe Routes
@app.route('/stripe/create-checkout-session', methods=['POST'])
@require_auth
def create_checkout_session():
    """Create Stripe checkout session with comprehensive validation"""
    try:
        data = request.get_json()
        plan_type = data.get('plan_type')
        
        # Validate plan type
        if not plan_type or plan_type not in ['basic', 'pro', 'enterprise']:
            return jsonify({'error': 'Invalid plan type'}), 400
        
        # Get user information
        user_id = request.current_user.get('user_id') or request.current_user.get('id')
        if not user_id:
            return jsonify({'error': 'User ID not found'}), 400
        
        # Check if user is guest
        if request.current_user.get('provider') == 'guest':
            return jsonify({'error': 'Guest users cannot subscribe. Please sign in with Google or GitHub.'}), 403
        
        # Generate URLs
        base_url = request.url_root.rstrip('/')
        success_url = f"{base_url}/subscription/success"
        cancel_url = f"{base_url}/subscription/cancel"
        
        # Create checkout session
        session = stripe_service.create_checkout_session(
            user_id, plan_type, success_url, cancel_url
        )
        
        if session:
            return jsonify({
                'checkout_url': session.url,
                'session_id': session.id
            })
        else:
            return jsonify({'error': 'Failed to create checkout session'}), 500
            
    except Exception as e:
        print(f"Error in create_checkout_session: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/stripe/subscription-status')
@require_auth
def get_subscription_status():
    """Get comprehensive subscription status for the current user"""
    try:
        user_id = request.current_user.get('user_id') or request.current_user.get('id')
        user = user_service.get_user_by_id(user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Check if user is guest
        if request.current_user.get('provider') == 'guest':
            return jsonify({
                'status': 'guest',
                'plan': 'free',
                'message': 'Guest users have limited access. Sign in to subscribe.'
            })
        
        # Get Stripe customer and subscription status
        customer = stripe_service.get_or_create_customer(user)
        if customer:
            status = stripe_service.get_subscription_status(customer.id)
            return jsonify(status)
        else:
            return jsonify({'status': 'inactive', 'plan': 'free'})
            
    except Exception as e:
        print(f"Error in get_subscription_status: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/stripe/cancel-subscription', methods=['POST'])
@require_auth
def cancel_subscription():
    """Cancel user's subscription with options"""
    try:
        data = request.get_json() or {}
        immediate = data.get('immediate', False)
        
        user_id = request.current_user.get('user_id') or request.current_user.get('id')
        user = user_service.get_user_by_id(user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        subscription_id = user.get('subscription_id')
        if not subscription_id:
            return jsonify({'error': 'No active subscription found'}), 404
        
        # Cancel subscription
        result = stripe_service.cancel_subscription(subscription_id, immediate)
        
        if result:
            return jsonify({
                'message': 'Subscription cancelled successfully',
                'immediate': immediate,
                'cancel_at_period_end': not immediate
            })
        else:
            return jsonify({'error': 'Failed to cancel subscription'}), 500
            
    except Exception as e:
        print(f"Error in cancel_subscription: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/stripe/reactivate-subscription', methods=['POST'])
@require_auth
def reactivate_subscription():
    """Reactivate a subscription that was set to cancel at period end"""
    try:
        user_id = request.current_user.get('user_id') or request.current_user.get('id')
        user = user_service.get_user_by_id(user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        subscription_id = user.get('subscription_id')
        if not subscription_id:
            return jsonify({'error': 'No subscription found'}), 404
        
        # Reactivate subscription
        result = stripe_service.reactivate_subscription(subscription_id)
        
        if result:
            return jsonify({
                'message': 'Subscription reactivated successfully',
                'cancel_at_period_end': False
            })
        else:
            return jsonify({'error': 'Failed to reactivate subscription'}), 500
            
    except Exception as e:
        print(f"Error in reactivate_subscription: {e}")
        return jsonify({'error': 'Internal server error'}), 500

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
        <head>
            <title>Subscription Successful - Tubby AI</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    margin: 0;
                    padding: 0;
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .container {
                    background: white;
                    border-radius: 16px;
                    padding: 3rem;
                    text-align: center;
                    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                    max-width: 500px;
                    margin: 2rem;
                }
                .success-icon {
                    width: 80px;
                    height: 80px;
                    background: #10b981;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    margin: 0 auto 2rem;
                }
                .success-icon svg {
                    width: 40px;
                    height: 40px;
                    color: white;
                }
                h1 {
                    color: #1f2937;
                    margin-bottom: 1rem;
                    font-size: 2rem;
                }
                p {
                    color: #6b7280;
                    margin-bottom: 2rem;
                    font-size: 1.1rem;
                    line-height: 1.6;
                }
                .btn {
                    background: #3b82f6;
                    color: white;
                    padding: 12px 24px;
                    border-radius: 8px;
                    text-decoration: none;
                    font-weight: 600;
                    transition: background 0.2s;
                    display: inline-block;
                }
                .btn:hover {
                    background: #2563eb;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="success-icon">
                    <svg fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
                    </svg>
                </div>
                <h1>Welcome to Tubby Pro!</h1>
                <p>Your subscription has been activated successfully. You now have access to all premium features including unlimited AI agent interactions, advanced terminal sessions, and priority support.</p>
                <a href="/" class="btn">Return to Dashboard</a>
            </div>
        </body>
    </html>
    """

@app.route('/subscription/cancel')
def subscription_cancel():
    """Subscription canceled page"""
    return """
    <html>
        <head>
            <title>Subscription Canceled - Tubby AI</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                    margin: 0;
                    padding: 0;
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .container {
                    background: white;
                    border-radius: 16px;
                    padding: 3rem;
                    text-align: center;
                    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                    max-width: 500px;
                    margin: 2rem;
                }
                .cancel-icon {
                    width: 80px;
                    height: 80px;
                    background: #ef4444;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    margin: 0 auto 2rem;
                }
                .cancel-icon svg {
                    width: 40px;
                    height: 40px;
                    color: white;
                }
                h1 {
                    color: #1f2937;
                    margin-bottom: 1rem;
                    font-size: 2rem;
                }
                p {
                    color: #6b7280;
                    margin-bottom: 2rem;
                    font-size: 1.1rem;
                    line-height: 1.6;
                }
                .btn {
                    background: #3b82f6;
                    color: white;
                    padding: 12px 24px;
                    border-radius: 8px;
                    text-decoration: none;
                    font-weight: 600;
                    transition: background 0.2s;
                    display: inline-block;
                    margin: 0 0.5rem;
                }
                .btn:hover {
                    background: #2563eb;
                }
                .btn-secondary {
                    background: #6b7280;
                }
                .btn-secondary:hover {
                    background: #4b5563;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="cancel-icon">
                    <svg fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
                    </svg>
                </div>
                <h1>Subscription Canceled</h1>
                <p>No worries! You can upgrade to a premium plan anytime to unlock advanced features and unlimited access to AI agents.</p>
                <a href="/" class="btn">Return to Dashboard</a>
                <a href="/#pricing" class="btn btn-secondary">View Plans</a>
            </div>
        </body>
    </html>
    """

# Whisper Voice Transcription Endpoint
@app.route('/api/whisper/transcribe', methods=['POST'])
def transcribe_audio():
    """Transcribe audio using OpenAI Whisper"""
    try:
        if 'audio' not in request.files:
            return jsonify({'error': 'No audio file provided'}), 400
        
        audio_file = request.files['audio']
        
        # Save audio to temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
            audio_file.save(temp_file.name)
            temp_path = temp_file.name
        
        try:
            # Use OpenAI Whisper API if API key is available
            openai_api_key = os.getenv('OPENAI_API_KEY')
            if openai_api_key:
                import openai
                openai.api_key = openai_api_key
                
                with open(temp_path, 'rb') as audio:
                    transcript = openai.Audio.transcribe("whisper-1", audio)
                    return jsonify({'text': transcript.text})
            else:
                # Fallback to local whisper (if installed)
                try:
                    result = subprocess.run([
                        'whisper', temp_path, '--output_format', 'txt'
                    ], capture_output=True, text=True, timeout=30)
                    
                    if result.returncode == 0:
                        # Read the output file
                        output_file = temp_path.replace('.wav', '.txt')
                        with open(output_file, 'r') as f:
                            text = f.read().strip()
                        return jsonify({'text': text})
                    else:
                        return jsonify({'error': 'Whisper transcription failed'}), 500
                except FileNotFoundError:
                    return jsonify({'error': 'Whisper not installed. Please install OpenAI Whisper or provide OPENAI_API_KEY'}), 500
        finally:
            # Clean up temporary file
            os.unlink(temp_path)
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/health')
def health_check():
    """Simple health check endpoint"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/debug/supabase')
def debug_supabase():
    """Debug Supabase connection"""
    try:
        if not user_service.supabase:
            return jsonify({'error': 'Supabase client not initialized'}), 500
        
        # Test basic connection
        result = user_service.supabase.table('users').select('id').limit(1).execute()
        return jsonify({
            'status': 'connected',
            'supabase_url': os.getenv('SUPABASE_URL'),
            'table_exists': True,
            'result': result.data
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'supabase_url': os.getenv('SUPABASE_URL'),
            'error': str(e)
        }), 500

@app.route('/debug/supabase/table/<table_name>')
def debug_supabase_table(table_name):
    """Debug specific table in Supabase"""
    try:
        if not user_service.supabase:
            return jsonify({'error': 'Supabase client not initialized'}), 500
        
        # Test specific table
        result = user_service.supabase.table(table_name).select('*').limit(1).execute()
        return jsonify({
            'status': 'connected',
            'table': table_name,
            'exists': True,
            'columns': list(result.columns.keys()) if result.columns else []
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'table': table_name,
            'exists': False,
            'error': str(e)
        }), 500

@app.route('/api/containers/status')
def get_container_status():
    """Get status of all containers"""
    status = {
        'gemini-1': 'unknown',
        'gemini-2': 'unknown',
        'redis': 'unknown'
    }
    
    try:
        # Check Gemini CLI Container 1
        response = requests.get(f"{GEMINI_CLI_URL_1}/health", timeout=10)
        if response.status_code == 200:
            status['gemini-1'] = 'running'
    except:
        status['gemini-1'] = 'stopped'
    
    try:
        # Check Gemini CLI Container 2
        response = requests.get(f"{GEMINI_CLI_URL_2}/health", timeout=10)
        if response.status_code == 200:
            status['gemini-2'] = 'running'
    except:
        status['gemini-2'] = 'stopped'
    

    
    try:
        # Check Redis container using ping command
        import subprocess
        result = subprocess.run(['redis-cli', '-h', 'redis', 'ping'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and 'PONG' in result.stdout:
            status['redis'] = 'running'
        else:
            status['redis'] = 'stopped'
    except:
        status['redis'] = 'unknown'
    
    return jsonify(status)

# Add MCP communication endpoint
@app.route('/api/mcp/communicate', methods=['POST'])
def mcp_communicate():
    """Enable cross-terminal communication via MCP"""
    data = request.get_json()
    source_terminal = data.get('source')
    target_terminal = data.get('target')
    message = data.get('message')
    
    if not all([source_terminal, target_terminal, message]):
        return jsonify({'error': 'Missing required fields'}), 400
    
    # Send via MCP router to keep routing logic centralized
    MCP_ROUTER_URL = os.getenv('MCP_ROUTER_URL', 'http://localhost:8080/forward')
    payload = {
        'target': target_terminal,
        'command': f'gemini --prompt "{message}"'
    }
    try:
        response = requests.post(MCP_ROUTER_URL, json=payload, timeout=120)
        result = response.json()
        
        # Broadcast the incoming message to the target terminal UI
        socketio.emit('mcp_message_received', {
            'source': source_terminal,
            'target': target_terminal,
            'message': message,
            'response': result
        })
        
        return jsonify({
            'source': source_terminal,
            'target': target_terminal,
            'message': message,
            'response': result
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/terminals/spawn', methods=['POST'])
def spawn_terminal():
    """Spawn a new Gemini CLI terminal container"""
    import subprocess
    import random
    
    try:
        # Generate a unique port and container name
        base_port = 8000
        used_ports = [8001, 8002]  # Existing ports
        
        # Find next available port
        port = base_port + 3  # Start from 8003
        while port in used_ports:
            port += 1
        
        container_name = f"gemini-cli-container-{port}"
        
        # Build and run the container
        cmd = [
            'docker', 'run', '-d',
            '--name', container_name,
            '--network', 'runmvpwithdockerandrequiredtools_ai-agent-network',
            '-p', f'{port}:{port}',
            '-e', f'GEMINI_API_KEY={os.getenv("GEMINI_API_KEY", "")}',
            '-e', f'MCP_PORT={port}',
            'runmvpwithdockerandrequiredtools-gemini-cli-container-1'  # Use existing image
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            container_id = result.stdout.strip()
            
            # Wait a moment for container to start
            import time
            time.sleep(2)
            
            # Check if container is healthy
            health_cmd = ['docker', 'exec', container_name, 'curl', '-f', f'http://localhost:{port}/health']
            health_result = subprocess.run(health_cmd, capture_output=True, text=True, timeout=30)
            
            if health_result.returncode == 0:
                return jsonify({
                    'success': True,
                    'container_id': container_id,
                    'container_name': container_name,
                    'port': port,
                    'terminal_id': f'gemini-{port}'
                })
            else:
                # Container started but health check failed
                return jsonify({
                    'success': False,
                    'error': 'Container started but health check failed'
                }), 500
        else:
            return jsonify({
                'success': False,
                'error': f'Failed to spawn container: {result.stderr}'
            }), 500
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/terminals/list', methods=['GET'])
def list_terminals():
    """List all running Gemini CLI terminals"""
    import subprocess
    
    try:
        # Get all running gemini containers
        cmd = ['docker', 'ps', '--filter', 'name=gemini-cli-container', '--format', '{{.Names}},{{.Ports}}']
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        terminals = []
        if result.returncode == 0:
            for line in result.stdout.strip().split('\n'):
                if line:
                    parts = line.split(',')
                    if len(parts) == 2:
                        name = parts[0]
                        ports = parts[1]
                        
                        # Extract port number
                        port_match = re.search(r'(\d+):\d+', ports)
                        if port_match:
                            port = int(port_match.group(1))
                            terminal_id = f'gemini-{port}'
                            terminals.append({
                                'name': name,
                                'port': port,
                                'terminal_id': terminal_id
                            })
        
        return jsonify({'terminals': terminals})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Collaborative workspace endpoints
@app.route('/api/workspace/upload', methods=['POST'])
def upload_to_workspace():
    """Upload code/files to the collaborative workspace"""
    try:
        data = request.get_json()
        file_content = data.get('content', '')
        file_name = data.get('name', 'untitled.txt')
        file_type = data.get('type', 'text')
        
        # Store in Redis with metadata
        file_key = f"workspace:file:{file_name}"
        file_data = {
            'name': file_name,
            'content': file_content,
            'type': file_type,
            'uploaded_at': str(datetime.now())
        }
        
        redis_client.set(file_key, json.dumps(file_data))
        
        # Add to workspace index
        workspace_files = redis_client.get('workspace:files')
        if workspace_files:
            files = json.loads(workspace_files)
        else:
            files = []
        
        if file_name not in [f['name'] for f in files]:
            files.append({
                'name': file_name,
                'type': file_type,
                'uploaded_at': str(datetime.now())
            })
            redis_client.set('workspace:files', json.dumps(files))
        
        # Broadcast to all terminals
        socketio.emit('workspace_updated', {
            'action': 'file_uploaded',
            'file_name': file_name,
            'file_type': file_type
        })
        
        return jsonify({
            'success': True,
            'message': f'File {file_name} uploaded to workspace',
            'file_name': file_name
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/workspace/files', methods=['GET'])
def list_workspace_files():
    """List all files in the collaborative workspace"""
    try:
        workspace_files = redis_client.get('workspace:files')
        if workspace_files:
            files = json.loads(workspace_files)
        else:
            files = []
        
        return jsonify({'files': files})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/workspace/file/<file_name>', methods=['GET'])
def get_workspace_file(file_name):
    """Get content of a specific file from workspace"""
    try:
        file_key = f"workspace:file:{file_name}"
        file_data = redis_client.get(file_key)
        
        if file_data:
            return jsonify(json.loads(file_data))
        else:
            return jsonify({'error': 'File not found'}), 404
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/workspace/task', methods=['POST'])
def create_collaborative_task():
    """Create a new collaborative task"""
    try:
        data = request.get_json()
        task_name = data.get('name', 'Untitled Task')
        task_description = data.get('description', '')
        assigned_terminals = data.get('terminals', [])
        
        task_id = f"task_{int(time.time())}"
        task_data = {
            'id': task_id,
            'name': task_name,
            'description': task_description,
            'assigned_terminals': assigned_terminals,
            'status': 'active',
            'created_at': str(datetime.now()),
            'progress': []
        }
        
        # Store task in Redis
        redis_client.set(f"workspace:task:{task_id}", json.dumps(task_data))
        
        # Add to task list
        tasks = redis_client.get('workspace:tasks')
        if tasks:
            task_list = json.loads(tasks)
        else:
            task_list = []
        
        task_list.append({
            'id': task_id,
            'name': task_name,
            'status': 'active',
            'assigned_terminals': assigned_terminals
        })
        redis_client.set('workspace:tasks', json.dumps(task_list))
        
        # Broadcast task creation
        socketio.emit('task_created', task_data)
        
        return jsonify({
            'success': True,
            'task_id': task_id,
            'task': task_data
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/workspace/tasks', methods=['GET'])
def list_tasks():
    """List all collaborative tasks"""
    try:
        tasks = redis_client.get('workspace:tasks')
        if tasks:
            return jsonify({'tasks': json.loads(tasks)})
        else:
            return jsonify({'tasks': []})
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/workspace/task/<task_id>/progress', methods=['POST'])
def update_task_progress(task_id):
    """Update progress on a collaborative task"""
    try:
        data = request.get_json()
        terminal_id = data.get('terminal')
        action = data.get('action')
        details = data.get('details', '')
        
        # Get current task
        task_key = f"workspace:task:{task_id}"
        task_data = redis_client.get(task_key)
        
        if task_data:
            task = json.loads(task_data)
            progress_entry = {
                'terminal': terminal_id,
                'action': action,
                'details': details,
                'timestamp': str(datetime.now())
            }
            
            task['progress'].append(progress_entry)
            redis_client.set(task_key, json.dumps(task))
            
            # Broadcast progress update
            socketio.emit('task_progress_updated', {
                'task_id': task_id,
                'progress': progress_entry
            })
            
            return jsonify({'success': True})
        else:
            return jsonify({'error': 'Task not found'}), 404
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@socketio.on('connect')
def handle_connect():
    """Handle client connection"""
    print('Client connected')
    emit('status', {'message': 'Connected to server'})

@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection"""
    print('Client disconnected')

@socketio.on('get_container_status')
def handle_get_container_status():
    """Send current container status to client"""
    try:
        # Check if containers are running
        status = {}
        
        # Check Gemini CLI containers
        try:
            response = requests.get(f"{GEMINI_CLI_URL_1}/health", timeout=5)
            status['gemini-1'] = {'status': 'running' if response.status_code == 200 else 'exited'}
        except:
            status['gemini-1'] = {'status': 'not_found'}
            
        try:
            response = requests.get(f"{GEMINI_CLI_URL_2}/health", timeout=5)
            status['gemini-2'] = {'status': 'running' if response.status_code == 200 else 'exited'}
        except:
            status['gemini-2'] = {'status': 'not_found'}
        
        emit('container_status', status)
    except Exception as e:
        print(f"Error getting container status: {e}")
        emit('container_status', {})

@socketio.on('mcp_function')
def handle_mcp_function(data):
    """Handle MCP function calls"""
    function_name = data.get('function')
    args = data.get('args')
    source_terminal = data.get('source_terminal')
    
    try:
        if function_name == 'get_shared_data':
            # Get shared data between terminals
            shared_data = redis_client.get('shared_data') or '{}'
            emit('mcp_function_result', {
                'function': function_name,
                'result': shared_data,
                'source_terminal': source_terminal
            })
        elif function_name == 'set_shared_data':
            # Set shared data between terminals
            redis_client.set('shared_data', args)
            emit('mcp_function_result', {
                'function': function_name,
                'result': 'Data shared successfully',
                'source_terminal': source_terminal
            })
        elif function_name == 'broadcast':
            # Broadcast message to all terminals
            emit('mcp_broadcast', {
                'message': args,
                'source_terminal': source_terminal
            }, broadcast=True)
        else:
            emit('mcp_function_result', {
                'function': function_name,
                'result': f'Unknown MCP function: {function_name}',
                'source_terminal': source_terminal
            })
    except Exception as e:
        emit('mcp_function_result', {
            'function': function_name,
            'result': f'Error: {str(e)}',
            'source_terminal': source_terminal
        })

@socketio.on('execute_command')
def handle_command(data):
    """Handle command execution from frontend"""
    command = data.get('command', '')
    terminal_type = data.get('terminal', 'system')
    
    if not command:
        emit('command_output', {'error': 'No command provided'})
        return
    
    try:
        if terminal_type == 'gemini-1':
            # Check if command looks like a system command (but allow gemini commands)
            system_commands = ['npm', 'npx', 'git', 'ls', 'pwd', 'cd', 'mkdir', 'rm', 'cp', 'mv']
            command_lower = command.lower()
            
            # Allow gemini commands even if they contain system command words
            if command_lower.startswith('gemini') or command_lower.startswith('--help') or command_lower.startswith('-h'):
                # This is a valid gemini command, proceed
                pass
            elif any(cmd in command_lower for cmd in system_commands):
                emit('command_output', {
                    'error': f'❌ This looks like a system command. Please use the System Terminal for commands like "{command.split()[0]}".\n💡 Gemini CLI terminal is for AI assistance only.',
                    'output': '',
                    'terminal': 'gemini-1'
                })
                return
            
            # Route to Gemini CLI Container 1
            try:
                response = requests.post(f"{GEMINI_CLI_URL_1}/execute", 
                                       json={'command': command}, timeout=60)
                result = response.json()
                emit('command_output', {
                    'output': result.get('output', ''),
                    'error': result.get('error', ''),
                    'terminal': 'gemini-1'
                })
            except requests.exceptions.ConnectionError:
                emit('command_output', {
                    'error': '❌ Gemini CLI Container 1 is not running.\n💡 To start it, run: docker-compose up gemini-cli-container-1\n💡 Or use the System Terminal for now.',
                    'output': '',
                    'terminal': 'gemini-1'
                })
            except Exception as e:
                emit('command_output', {
                    'error': f'❌ Error connecting to Gemini CLI Container 1: {str(e)}\n💡 Try using the System Terminal instead.',
                    'output': '',
                    'terminal': 'gemini-1'
                })
            
        elif terminal_type == 'gemini-2':
            # Check if command looks like a system command (but allow gemini commands)
            system_commands = ['npm', 'npx', 'git', 'ls', 'pwd', 'cd', 'mkdir', 'rm', 'cp', 'mv']
            command_lower = command.lower()
            
            # Allow gemini commands even if they contain system command words
            if command_lower.startswith('gemini') or command_lower.startswith('--prompt') or command_lower.startswith('-p'):
                # This is a valid gemini command, proceed
                pass
            elif any(cmd in command_lower for cmd in system_commands):
                emit('command_output', {
                    'error': f'❌ This looks like a system command. Please use the System Terminal for commands like "{command.split()[0]}".\n💡 Gemini CLI terminal is for AI chat assistance only.',
                    'output': '',
                    'terminal': 'gemini-2'
                })
                return
            
            # Route to Gemini CLI Container 2
            try:
                response = requests.post(f"{GEMINI_CLI_URL_2}/execute", 
                                       json={'command': command}, timeout=60)
                result = response.json()
                emit('command_output', {
                    'output': result.get('output', ''),
                    'error': result.get('error', ''),
                    'terminal': 'gemini-2'
                })
            except requests.exceptions.ConnectionError:
                emit('command_output', {
                    'error': '❌ Gemini CLI Container 2 is not running.\n💡 To start it, run: docker-compose up gemini-cli-container-2\n💡 Or use the System Terminal for now.',
                    'output': '',
                    'terminal': 'gemini-2'
                })
            except Exception as e:
                emit('command_output', {
                    'error': f'❌ Error connecting to Gemini CLI Container 2: {str(e)}\n💡 Try using the System Terminal instead.',
                    'output': '',
                    'terminal': 'gemini-2'
                })
            
        elif terminal_type == 'gemini-3':
            # Check if command looks like a system command (but allow gemini commands)
            system_commands = ['npm', 'npx', 'git', 'ls', 'pwd', 'cd', 'mkdir', 'rm', 'cp', 'mv']
            command_lower = command.lower()
            
            # Allow gemini commands even if they contain system command words
            if command_lower.startswith('gemini') or command_lower.startswith('--prompt') or command_lower.startswith('-p'):
                # This is a valid gemini command, proceed
                pass
            elif any(cmd in command_lower for cmd in system_commands):
                emit('command_output', {
                    'error': f'❌ This looks like a system command. Please use the System Terminal for commands like "{command.split()[0]}".\n💡 Gemini CLI terminal is for AI chat assistance only.',
                    'output': '',
                    'terminal': 'gemini-3'
                })
                return
            
            # Route to Gemini CLI Container 3
            response = requests.post(f"{GEMINI_CLI_URL_3}/execute", 
                                   json={'command': command}, timeout=60)
            result = response.json()
            emit('command_output', {
                'output': result.get('output', ''),
                'error': result.get('error', ''),
                'terminal': 'gemini-3'
            })
            
        else:
            # System command - execute locally
            import subprocess
            import shlex
            
            try:
                # Convert command to lowercase for case-insensitive checking
                command_lower = command.lower()
                
                # Handle multiple commands on one line
                if ';' in command or '&&' in command or '||' in command:
                    # Use shell=True for command chaining
                    result = subprocess.run(
                        command,
                        shell=True,
                        capture_output=True,
                        text=True,
                        timeout=30
                    )
                else:
                    # Use subprocess to execute system commands
                    result = subprocess.run(
                        shlex.split(command),
                        capture_output=True,
                        text=True,
                        timeout=30
                    )
                
                output = result.stdout if result.stdout else ''
                error = result.stderr if result.stderr else ''
                
                # If command not found, provide helpful suggestions
                if 'command not found' in error.lower() or 'not recognized' in error.lower():
                    if 'ls' in command_lower:
                        error += '\n💡 Try: dir (Windows) or ls (Linux/Mac)'
                    elif 'dir' in command_lower:
                        error += '\n💡 Try: ls (Linux/Mac) or dir (Windows)'
                
                emit('command_output', {
                    'output': output,
                    'error': error,
                    'terminal': 'system'
                })
                
            except subprocess.TimeoutExpired:
                emit('command_output', {
                    'error': 'Command timed out after 30 seconds',
                    'output': '',
                    'terminal': 'system'
                })
            except FileNotFoundError:
                emit('command_output', {
                    'error': f'Command not found: {command.split()[0]}',
                    'output': '',
                    'terminal': 'system'
                })
            except Exception as e:
                emit('command_output', {
                    'error': f'System command error: {str(e)}',
                    'output': '',
                    'terminal': 'system'
                })
            
    except requests.exceptions.Timeout as e:
        emit('command_output', {
            'error': f'Command timed out. The AI agent may be processing a complex request. Please try again.',
            'output': '',
            'terminal': terminal_type
        })
    except requests.exceptions.ConnectionError as e:
        emit('command_output', {
            'error': f'Cannot connect to {terminal_type} container. Please check if the container is running.',
            'output': '',
            'terminal': terminal_type
        })
    except requests.exceptions.RequestException as e:
        emit('command_output', {
            'error': f'Container communication error: {str(e)}',
            'output': '',
            'terminal': terminal_type
        })

if __name__ == '__main__':
    try:
        socketio.run(app, host='0.0.0.0', port=5004, debug=False, allow_unsafe_werkzeug=True)
    except Exception as e:
        print(f"Error starting server: {e}")
        # Fallback to regular Flask
        app.run(host='0.0.0.0', port=5004, debug=False) 