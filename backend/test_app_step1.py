from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return "Hello World!"

@app.route('/ping')
def ping():
    return "pong"

@app.route('/test')
def test():
    return jsonify({"message": "Test endpoint working!"})

# Test 1: Add CORS
try:
    from flask_cors import CORS
    CORS(app, origins=['http://localhost:3001'], supports_credentials=True)
    print("✅ CORS added successfully")
except Exception as e:
    print(f"❌ CORS failed: {e}")

# Test 2: Add basic imports
try:
    import os
    import requests
    import json
    import time
    from datetime import datetime
    from dotenv import load_dotenv
    print("✅ Basic imports successful")
except Exception as e:
    print(f"❌ Basic imports failed: {e}")

# Test 3: Add service imports (but don't initialize)
try:
    from supabase_client import supabase_manager
    print("✅ Supabase client import successful")
except Exception as e:
    print(f"❌ Supabase client import failed: {e}")

try:
    from services.oauth_service import OAuthService
    print("✅ OAuth service import successful")
except Exception as e:
    print(f"❌ OAuth service import failed: {e}")

try:
    from services.user_service import UserService
    print("✅ User service import successful")
except Exception as e:
    print(f"❌ User service import failed: {e}")

try:
    from services.stripe_service import StripeService
    print("✅ Stripe service import successful")
except Exception as e:
    print(f"❌ Stripe service import failed: {e}")

if __name__ == '__main__':
    print("Starting step-by-step Flask test app...")
    print("Routes:")
    for rule in app.url_map.iter_rules():
        print(f"  {rule.rule} -> {rule.endpoint}")
    app.run(host='127.0.0.1', port=5004, debug=True) 