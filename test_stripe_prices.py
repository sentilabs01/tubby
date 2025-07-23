#!/usr/bin/env python3
"""
Test script to check Stripe price IDs
"""
import os
import stripe
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_stripe_prices():
    """Test Stripe price IDs"""
    print("🔍 Testing Stripe Price IDs...")
    
    stripe_key = os.getenv('STRIPE_SECRET_KEY')
    if not stripe_key:
        print("❌ No Stripe secret key found")
        return
    
    stripe.api_key = stripe_key
    
    # Price IDs from environment variables
    price_ids = [
        os.getenv('STRIPE_BASIC_PRICE_ID'),      # Basic
        os.getenv('STRIPE_PRO_PRICE_ID'),        # Pro
        os.getenv('STRIPE_ENTERPRISE_PRICE_ID')  # Enterprise
    ]
    
    print(f"Testing {len(price_ids)} price IDs...")
    
    for price_id in price_ids:
        try:
            price = stripe.Price.retrieve(price_id)
            print(f"✅ {price_id}: {price.unit_amount / 100} {price.currency} - {price.nickname or 'No nickname'}")
        except stripe.error.InvalidRequestError as e:
            print(f"❌ {price_id}: {e}")
        except stripe.error.AuthenticationError:
            print(f"❌ {price_id}: Authentication failed - check API key")
        except Exception as e:
            print(f"❌ {price_id}: {e}")
    
    print("\n💡 If all price IDs fail, they might belong to a different Stripe account.")
    print("   Check your Stripe Dashboard for the correct price IDs.")

if __name__ == "__main__":
    test_stripe_prices() 