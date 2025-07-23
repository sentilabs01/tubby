#!/usr/bin/env python3
"""
List all Stripe price IDs in the account
"""
import os
import stripe
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def list_stripe_prices():
    """List all available price IDs"""
    print("🔍 Listing all Stripe Price IDs...")
    
    stripe_key = os.getenv('STRIPE_SECRET_KEY')
    if not stripe_key:
        print("❌ No Stripe secret key found")
        return
    
    stripe.api_key = stripe_key
    
    try:
        # Get all prices
        prices = stripe.Price.list(limit=100, active=True)
        
        print(f"✅ Found {len(prices.data)} active prices:")
        print("-" * 80)
        
        for price in prices.data:
            print(f"ID: {price.id}")
            print(f"Amount: {price.unit_amount / 100} {price.currency}")
            print(f"Nickname: {price.nickname or 'No nickname'}")
            print(f"Product: {price.product}")
            print(f"Active: {price.active}")
            print("-" * 80)
            
    except Exception as e:
        print(f"❌ Error listing prices: {e}")

if __name__ == "__main__":
    list_stripe_prices() 