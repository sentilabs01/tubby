#!/usr/bin/env python3
"""
Test OAuth redirect URLs
"""

import requests

def test_oauth_urls():
    """Test OAuth redirect URLs"""
    print("🧪 Testing OAuth Redirect URLs")
    print("=" * 50)
    
    # Test Google OAuth
    print("\n1. Testing Google OAuth:")
    try:
        response = requests.get('http://localhost:3002/auth/google', allow_redirects=False)
        print(f"   Status: {response.status_code}")
        if response.status_code == 302:
            location = response.headers.get('Location', 'No location')
            print(f"   Redirect URL: {location}")
        else:
            print(f"   Response: {response.text[:200]}...")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Test GitHub OAuth
    print("\n2. Testing GitHub OAuth:")
    try:
        response = requests.get('http://localhost:3002/auth/github', allow_redirects=False)
        print(f"   Status: {response.status_code}")
        if response.status_code == 302:
            location = response.headers.get('Location', 'No location')
            print(f"   Redirect URL: {location}")
        else:
            print(f"   Response: {response.text[:200]}...")
    except Exception as e:
        print(f"   Error: {e}")
    
    print("\n" + "=" * 50)

if __name__ == "__main__":
    test_oauth_urls() 