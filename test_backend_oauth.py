#!/usr/bin/env python3
"""
Test backend OAuth endpoints directly
"""

import requests

def test_backend_oauth():
    """Test backend OAuth endpoints"""
    print("🧪 Testing Backend OAuth Endpoints")
    print("=" * 50)
    
    # Test Google OAuth
    print("\n1. Testing Google OAuth (Backend):")
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
    print("\n2. Testing GitHub OAuth (Backend):")
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
    test_backend_oauth() 