#!/usr/bin/env python3
"""
Simple backend test
"""

import requests

def test_backend():
    """Test basic backend functionality"""
    print("🧪 Testing Backend Basic Functionality")
    print("=" * 50)
    
    # Test health endpoint
    print("\n1. Testing Health Endpoint:")
    try:
        response = requests.get('http://localhost:3007/health')
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.text}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Test guest auth
    print("\n2. Testing Guest Auth:")
    try:
        response = requests.get('http://localhost:3007/auth/guest')
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.text}")
    except Exception as e:
        print(f"   Error: {e}")
    
    print("\n" + "=" * 50)

if __name__ == "__main__":
    test_backend() 