#!/usr/bin/env python3
"""
Test script to verify Stripe payment functionality
"""
import os
import sys
import requests
import json
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

def test_stripe_configuration():
    """Test if Stripe is properly configured"""
    print("🧪 Testing Stripe Configuration...")
    
    # Test environment variables
    stripe_secret = os.getenv('STRIPE_SECRET_KEY')
    basic_price_id = os.getenv('STRIPE_BASIC_PRICE_ID')
    pro_price_id = os.getenv('STRIPE_PRO_PRICE_ID')
    enterprise_price_id = os.getenv('STRIPE_ENTERPRISE_PRICE_ID')
    
    print(f"✅ Stripe Secret Key: {'Set' if stripe_secret else '❌ Missing'}")
    print(f"✅ Basic Price ID: {basic_price_id}")
    print(f"✅ Pro Price ID: {pro_price_id}")
    print(f"✅ Enterprise Price ID: {enterprise_price_id}")
    
    return all([stripe_secret, basic_price_id, pro_price_id, enterprise_price_id])

def test_backend_health():
    """Test backend health endpoint"""
    print("\n🏥 Testing Backend Health...")
    
    try:
        response = requests.get('http://localhost:5004/health')
        if response.status_code == 200:
            print("✅ Backend is healthy")
            return True
        else:
            print(f"❌ Backend health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Backend health check error: {e}")
        return False

def test_stripe_checkout_endpoint():
    """Test Stripe checkout endpoint"""
    print("\n💳 Testing Stripe Checkout Endpoint...")
    
    # Test data
    test_data = {
        'plan_type': 'basic'
    }
    
    try:
        response = requests.post(
            'http://localhost:5004/stripe/create-checkout-session',
            json=test_data,
            headers={'Content-Type': 'application/json'}
        )
        
        print(f"Response Status: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Checkout session created successfully")
            print(f"Checkout URL: {data.get('checkout_url', 'Not found')}")
            return True
        else:
            print(f"❌ Checkout session creation failed")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Checkout endpoint error: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Starting Stripe Payment Tests\n")
    
    # Test 1: Configuration
    config_ok = test_stripe_configuration()
    
    # Test 2: Backend Health
    health_ok = test_backend_health()
    
    # Test 3: Stripe Checkout
    checkout_ok = test_stripe_checkout_endpoint()
    
    # Summary
    print("\n📊 Test Results:")
    print(f"Configuration: {'✅ PASS' if config_ok else '❌ FAIL'}")
    print(f"Backend Health: {'✅ PASS' if health_ok else '❌ FAIL'}")
    print(f"Stripe Checkout: {'✅ PASS' if checkout_ok else '❌ FAIL'}")
    
    if all([config_ok, health_ok, checkout_ok]):
        print("\n🎉 All tests passed! Stripe payment functionality is working.")
    else:
        print("\n⚠️  Some tests failed. Check the configuration.")

if __name__ == '__main__':
    main() 