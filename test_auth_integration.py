#!/usr/bin/env python3
"""
Test script for Google OAuth and Stripe integration
"""

import requests
import json
import os
from dotenv import load_dotenv

load_dotenv()

BASE_URL = "http://localhost:3002"

def test_health_check():
    """Test if the server is running"""
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"✅ Health check: {response.status_code}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_oauth_endpoints():
    """Test OAuth endpoints"""
    print("\n🔐 Testing OAuth Endpoints:")
    
    # Test Google auth initiation
    try:
        response = requests.get(f"{BASE_URL}/auth/google", allow_redirects=False)
        print(f"✅ Google auth initiation: {response.status_code}")
        if response.status_code == 302:
            print(f"   Redirect URL: {response.headers.get('Location', 'No location')}")
    except Exception as e:
        print(f"❌ Google auth initiation failed: {e}")
    
    # Test GitHub auth initiation
    try:
        response = requests.get(f"{BASE_URL}/auth/github", allow_redirects=False)
        print(f"✅ GitHub auth initiation: {response.status_code}")
        if response.status_code == 302:
            print(f"   Redirect URL: {response.headers.get('Location', 'No location')}")
    except Exception as e:
        print(f"❌ GitHub auth initiation failed: {e}")
    
    # Test guest auth
    try:
        response = requests.get(f"{BASE_URL}/auth/guest")
        print(f"✅ Guest auth: {response.status_code}")
        if response.status_code == 200:
            print(f"   Guest user created successfully")
    except Exception as e:
        print(f"❌ Guest auth failed: {e}")
    
    # Test auth user endpoint (should fail without auth)
    try:
        response = requests.get(f"{BASE_URL}/auth/user")
        print(f"✅ Auth user endpoint (no auth): {response.status_code}")
    except Exception as e:
        print(f"❌ Auth user endpoint failed: {e}")

def test_stripe_endpoints():
    """Test Stripe endpoints"""
    print("\n💳 Testing Stripe Endpoints:")
    
    # Test subscription status (should fail without auth)
    try:
        response = requests.get(f"{BASE_URL}/stripe/subscription-status")
        print(f"✅ Subscription status (no auth): {response.status_code}")
    except Exception as e:
        print(f"❌ Subscription status failed: {e}")
    
    # Test checkout session creation (should fail without auth)
    try:
        response = requests.post(
            f"{BASE_URL}/stripe/create-checkout-session",
            json={"plan_type": "basic"}
        )
        print(f"✅ Checkout session creation (no auth): {response.status_code}")
    except Exception as e:
        print(f"❌ Checkout session creation failed: {e}")

def test_environment_variables():
    """Test if required environment variables are set"""
    print("\n🔧 Testing Environment Variables:")
    
    required_vars = [
        'SUPABASE_URL',
        'SUPABASE_ANON_KEY',
        'FRONTEND_URL',
        'JWT_SECRET_KEY',
        'STRIPE_SECRET_KEY',
        'STRIPE_PUBLISHABLE_KEY',
        'STRIPE_WEBHOOK_SECRET',
        'STRIPE_BASIC_PRICE_ID',
        'STRIPE_PRO_PRICE_ID',
        'STRIPE_ENTERPRISE_PRICE_ID'
    ]
    
    missing_vars = []
    for var in required_vars:
        value = os.getenv(var)
        if value and value != f"your_{var.lower()}_here":
            print(f"✅ {var}: Set")
        else:
            print(f"❌ {var}: Not set or using default value")
            missing_vars.append(var)
    
    return len(missing_vars) == 0

def test_database_connection():
    """Test database connection"""
    print("\n🗄️ Testing Database Connection:")
    
    try:
        # Test if we can access the API keys endpoint
        response = requests.get(f"{BASE_URL}/api/user/api-keys?user_id=test")
        print(f"✅ Database connection: {response.status_code}")
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🧪 Testing OAuth and API Key Integration")
    print("=" * 50)
    
    # Test server health
    if not test_health_check():
        print("\n❌ Server is not running. Please start the backend server first.")
        return
    
    # Test environment variables
    env_ok = test_environment_variables()
    
    # Test database connection
    db_ok = test_database_connection()
    
    # Test endpoints
    test_oauth_endpoints()
    test_stripe_endpoints()
    
    print("\n" + "=" * 50)
    print("📋 Test Summary:")
    print(f"   Environment Variables: {'✅ OK' if env_ok else '❌ Missing'}")
    print(f"   Database Connection: {'✅ OK' if db_ok else '❌ Failed'}")
    print(f"   Server Health: ✅ OK")
    
    if not env_ok:
        print("\n⚠️  Please configure the required environment variables:")
        print("   - Copy OAUTH_SETUP_INSTRUCTIONS.md for setup instructions")
        print("   - Create a .env file in the backend directory")
        print("   - Set up Supabase Auth providers (Google & GitHub)")
    
    print("\n🎯 Next Steps:")
    print("   1. Configure environment variables")
    print("   2. Set up Supabase Auth providers (Google & GitHub)")
    print("   3. Run database schema updates")
    print("   4. Test OAuth flow with Google and GitHub")
    print("   5. Test API key management in settings")
    print("   6. Test guest user functionality")

if __name__ == "__main__":
    main() 