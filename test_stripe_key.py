#!/usr/bin/env python3
"""
Test script to verify Stripe API key
"""
import os
import stripe
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_stripe_key():
    """Test if Stripe API key is valid"""
    print("🔍 Testing Stripe API Key...")
    
    # Get the API key
    stripe_key = os.getenv('STRIPE_SECRET_KEY')
    
    if not stripe_key:
        print("❌ No Stripe secret key found in environment variables")
        return
    
    print(f"✅ Stripe Key Found: {stripe_key[:20]}...{stripe_key[-4:]}")
    
    # Check key format
    if not stripe_key.startswith('sk_'):
        print("❌ Invalid Stripe key format - should start with 'sk_'")
        return
    
    if 'live' in stripe_key:
        print("✅ Using Live Stripe key")
    elif 'test' in stripe_key:
        print("✅ Using Test Stripe key")
    else:
        print("⚠️  Unknown Stripe key type")
    
    # Test the key with Stripe API
    try:
        stripe.api_key = stripe_key
        
        # Try to retrieve account info
        account = stripe.Account.retrieve()
        print(f"✅ Stripe API Key is valid!")
        print(f"   Account ID: {account.id}")
        print(f"   Account Type: {account.type}")
        
        # Test price retrieval
        try:
            basic_price = stripe.Price.retrieve('price_1RnI7vKoB6ANfJLNft6upLIC')
            print(f"✅ Basic Price ID is valid: {basic_price.unit_amount / 100} {basic_price.currency}")
        except stripe.error.InvalidRequestError as e:
            print(f"❌ Basic Price ID error: {e}")
        
    except stripe.error.AuthenticationError:
        print("❌ Stripe API Key is invalid - Authentication failed")
    except stripe.error.APIConnectionError:
        print("❌ Stripe API connection failed - check internet connection")
    except Exception as e:
        print(f"❌ Stripe API error: {e}")

if __name__ == "__main__":
    test_stripe_key() 