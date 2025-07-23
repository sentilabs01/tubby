#!/usr/bin/env python3
"""
Test script to verify Stripe configuration and identify checkout session issues
"""

import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv('../.env')

def test_stripe_config():
    """Test Stripe configuration"""
    print("🔍 Testing Stripe Configuration...")
    
    # Check environment variables
    stripe_secret_key = os.getenv('STRIPE_SECRET_KEY')
    stripe_publishable_key = os.getenv('STRIPE_PUBLISHABLE_KEY')
    stripe_basic_price_id = os.getenv('STRIPE_BASIC_PRICE_ID')
    stripe_pro_price_id = os.getenv('STRIPE_PRO_PRICE_ID')
    stripe_enterprise_price_id = os.getenv('STRIPE_ENTERPRISE_PRICE_ID')
    
    print(f"✅ Stripe Secret Key: {'✅ Set' if stripe_secret_key else '❌ Missing'}")
    print(f"✅ Stripe Publishable Key: {'✅ Set' if stripe_publishable_key else '❌ Missing'}")
    print(f"✅ Basic Price ID: {'✅ Set' if stripe_basic_price_id else '❌ Missing'}")
    print(f"✅ Pro Price ID: {'✅ Set' if stripe_pro_price_id else '❌ Missing'}")
    print(f"✅ Enterprise Price ID: {'✅ Set' if stripe_enterprise_price_id else '❌ Missing'}")
    
    # Check if secret key looks correct
    if stripe_secret_key:
        if stripe_secret_key.startswith('sk_live_'):
            print("✅ Stripe Secret Key format: Correct (Live)")
        elif stripe_secret_key.startswith('sk_test_'):
            print("✅ Stripe Secret Key format: Correct (Test)")
        else:
            print("❌ Stripe Secret Key format: Incorrect (should start with sk_live_ or sk_test_)")
    
    # Check if publishable key looks correct
    if stripe_publishable_key:
        if stripe_publishable_key.startswith('pk_live_'):
            print("✅ Stripe Publishable Key format: Correct (Live)")
        elif stripe_publishable_key.startswith('pk_test_'):
            print("✅ Stripe Publishable Key format: Correct (Test)")
        else:
            print("❌ Stripe Publishable Key format: Incorrect (should start with pk_live_ or pk_test_)")
    
    # Test Stripe API connection
    if stripe_secret_key:
        try:
            import stripe
            stripe.api_key = stripe_secret_key
            
            # Test API connection
            account = stripe.Account.retrieve()
            print(f"✅ Stripe API Connection: Successful")
            print(f"   Account ID: {account.id}")
            print(f"   Account Type: {account.type}")
            
            # Test price retrieval
            if stripe_basic_price_id:
                try:
                    price = stripe.Price.retrieve(stripe_basic_price_id)
                    print(f"✅ Basic Price: Valid (${price.unit_amount/100}/month)")
                except Exception as e:
                    print(f"❌ Basic Price: Invalid - {e}")
            
            if stripe_pro_price_id:
                try:
                    price = stripe.Price.retrieve(stripe_pro_price_id)
                    print(f"✅ Pro Price: Valid (${price.unit_amount/100}/month)")
                except Exception as e:
                    print(f"❌ Pro Price: Invalid - {e}")
            
            if stripe_enterprise_price_id:
                try:
                    price = stripe.Price.retrieve(stripe_enterprise_price_id)
                    print(f"✅ Enterprise Price: Valid (${price.unit_amount/100}/month)")
                except Exception as e:
                    print(f"❌ Enterprise Price: Invalid - {e}")
                    
        except Exception as e:
            print(f"❌ Stripe API Connection Failed: {e}")
    else:
        print("❌ Cannot test Stripe API - no secret key configured")

def test_backend_connection():
    """Test backend connection"""
    print("\n🔍 Testing Backend Connection...")
    
    try:
        import requests
        response = requests.get('http://localhost:5004/health', timeout=5)
        if response.status_code == 200:
            print("✅ Backend Health Check: Successful")
        else:
            print(f"❌ Backend Health Check: HTTP {response.status_code}")
    except Exception as e:
        print(f"❌ Backend Connection Failed: {e}")

def test_auth_endpoint():
    """Test authentication endpoint"""
    print("\n🔍 Testing Authentication Endpoint...")
    
    try:
        import requests
        response = requests.get('http://localhost:5004/auth/user', timeout=5)
        print(f"Auth endpoint status: {response.status_code}")
        if response.status_code == 401:
            print("✅ Auth endpoint: Correctly returns 401 for unauthenticated requests")
        else:
            print(f"⚠️  Auth endpoint: Unexpected status {response.status_code}")
    except Exception as e:
        print(f"❌ Auth endpoint test failed: {e}")

if __name__ == "__main__":
    test_stripe_config()
    test_backend_connection()
    test_auth_endpoint() 