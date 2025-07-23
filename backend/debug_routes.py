#!/usr/bin/env python3
"""
Comprehensive Flask Route Debug Script
Based on STRIPE_DEBUG.md and LOCAL_DEV_SETUP.md
"""

import os
import sys
import requests
import json
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv

# Load environment variables
load_dotenv('.env')

print("🔍 FLASK ROUTE DEBUG SCRIPT")
print("=" * 50)

# Test 1: Environment Variables
print("\n1️⃣ Testing Environment Variables:")
env_vars = [
    'STRIPE_SECRET_KEY',
    'STRIPE_PUBLISHABLE_KEY', 
    'STRIPE_BASIC_PRICE_ID',
    'STRIPE_PRO_PRICE_ID',
    'STRIPE_ENTERPRISE_PRICE_ID',
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'SUPABASE_SERVICE_ROLE_KEY'
]

for var in env_vars:
    value = os.getenv(var)
    if value:
        print(f"✅ {var}: {value[:20]}...")
    else:
        print(f"❌ {var}: NOT SET")

# Test 2: Create minimal Flask app
print("\n2️⃣ Creating Minimal Flask App:")
app = Flask(__name__)
app.config['SECRET_KEY'] = 'debug-secret-key'

# Add CORS
CORS(app, origins=['http://localhost:3001'], supports_credentials=True)

# Test routes
@app.route('/')
def home():
    return "Home route working!"

@app.route('/ping')
def ping():
    return "pong"

@app.route('/test-json')
def test_json():
    return jsonify({"message": "JSON route working!", "status": "success"})

@app.route('/test-stripe-import')
def test_stripe_import():
    try:
        import stripe
        return jsonify({
            "stripe_import": "success",
            "stripe_version": getattr(stripe, '__version__', 'unknown'),
            "stripe_file": stripe.__file__,
            "has_checkout": hasattr(stripe, 'checkout'),
            "has_session": hasattr(stripe.checkout, 'Session') if hasattr(stripe, 'checkout') else False
        })
    except Exception as e:
        return jsonify({"stripe_import": "failed", "error": str(e)}), 500

@app.route('/test-stripe-config')
def test_stripe_config():
    try:
        import stripe
        stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
        
        if not stripe.api_key:
            return jsonify({"error": "STRIPE_SECRET_KEY not set"}), 500
            
        # Test basic Stripe API call
        account = stripe.Account.retrieve()
        return jsonify({
            "stripe_config": "success",
            "account_id": account.id,
            "api_key_set": bool(stripe.api_key)
        })
    except Exception as e:
        return jsonify({"stripe_config": "failed", "error": str(e)}), 500

@app.route('/test-services')
def test_services():
    results = {}
    
    # Test Supabase client
    try:
        from supabase_client import supabase_manager
        results['supabase'] = "import_success"
    except Exception as e:
        results['supabase'] = f"import_failed: {str(e)}"
    
    # Test OAuth service
    try:
        from services.oauth_service import OAuthService
        oauth = OAuthService()
        results['oauth'] = "init_success"
    except Exception as e:
        results['oauth'] = f"init_failed: {str(e)}"
    
    # Test User service
    try:
        from services.user_service import UserService
        user = UserService()
        results['user'] = "init_success"
    except Exception as e:
        results['user'] = f"init_failed: {str(e)}"
    
    # Test Stripe service
    try:
        from services.stripe_service import StripeService
        stripe = StripeService()
        results['stripe'] = "init_success"
    except Exception as e:
        results['stripe'] = f"init_failed: {str(e)}"
    
    return jsonify(results)

# Test 3: Print all routes
print("\n3️⃣ Registered Routes:")
for rule in app.url_map.iter_rules():
    print(f"  {rule.rule} -> {rule.endpoint}")

# Test 4: Start server
if __name__ == '__main__':
    print("\n4️⃣ Starting Debug Server...")
    print("Server will run on http://127.0.0.1:5004")
    print("Test these endpoints:")
    print("  http://127.0.0.1:5004/")
    print("  http://127.0.0.1:5004/ping")
    print("  http://127.0.0.1:5004/test-json")
    print("  http://127.0.0.1:5004/test-stripe-import")
    print("  http://127.0.0.1:5004/test-stripe-config")
    print("  http://127.0.0.1:5004/test-services")
    print("\nPress Ctrl+C to stop")
    
    app.run(host='127.0.0.1', port=5004, debug=True) 