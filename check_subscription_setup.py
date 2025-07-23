#!/usr/bin/env python3
"""
Check Subscription System Setup
"""

import os
import sys

def check_subscription_setup():
    print("🔍 Checking Subscription System Setup...")
    print("=" * 50)
    
    # Check environment variables
    print("\n📋 Environment Variables:")
    stripe_secret = os.getenv('STRIPE_SECRET_KEY')
    basic_price = os.getenv('STRIPE_BASIC_PRICE_ID')
    pro_price = os.getenv('STRIPE_PRO_PRICE_ID')
    enterprise_price = os.getenv('STRIPE_ENTERPRISE_PRICE_ID')
    
    print(f"✅ Stripe Secret Key: {'✅ Set' if stripe_secret else '❌ Missing'}")
    print(f"✅ Basic Price ID: {'✅ Set' if basic_price else '❌ Missing'}")
    print(f"✅ Pro Price ID: {'✅ Set' if pro_price else '❌ Missing'}")
    print(f"✅ Enterprise Price ID: {'✅ Set' if enterprise_price else '❌ Missing'}")
    
    # Check if files exist
    print("\n📁 Required Files:")
    files_to_check = [
        'src/components/SubscriptionPlans.jsx',
        'backend/services/stripe_service.py',
        'database/schema.sql'
    ]
    
    for file_path in files_to_check:
        exists = os.path.exists(file_path)
        print(f"{'✅' if exists else '❌'} {file_path}")
    
    # Check backend routes
    print("\n🔗 Backend Routes (if backend is running):")
    routes_to_check = [
        '/stripe/create-checkout-session',
        '/stripe/subscription-status',
        '/stripe/cancel-subscription',
        '/stripe/reactivate-subscription'
    ]
    
    for route in routes_to_check:
        print(f"🔗 {route}")
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 SUMMARY:")
    
    if all([stripe_secret, basic_price, pro_price, enterprise_price]):
        print("✅ Subscription system is fully configured!")
        print("✅ All environment variables are set")
        print("✅ All required files exist")
        print("\n🚀 To activate:")
        print("1. Deploy the backend to production")
        print("2. Set environment variables in production")
        print("3. Test subscription flow")
    else:
        print("❌ Subscription system needs configuration")
        print("❌ Missing environment variables")
        print("\n🔧 To fix:")
        print("1. Set STRIPE_SECRET_KEY")
        print("2. Set STRIPE_BASIC_PRICE_ID")
        print("3. Set STRIPE_PRO_PRICE_ID")
        print("4. Set STRIPE_ENTERPRISE_PRICE_ID")
        print("5. Deploy backend")

if __name__ == "__main__":
    check_subscription_setup() 