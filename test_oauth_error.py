#!/usr/bin/env python3
"""
Test OAuth error details
"""

import requests

def test_oauth_error():
    """Test OAuth error details"""
    print("🧪 Testing OAuth Error Details")
    print("=" * 50)
    
    # Test Google OAuth
    print("\n1. Testing Google OAuth Error:")
    try:
        response = requests.get('http://localhost:3007/auth/google', allow_redirects=False)
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.text}")
    except Exception as e:
        print(f"   Error: {e}")
    
    print("\n" + "=" * 50)

if __name__ == "__main__":
    test_oauth_error() 