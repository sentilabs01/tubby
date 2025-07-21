#!/usr/bin/env python3
"""
Test script to verify API key functionality
"""

import requests
import json

BASE_URL = "http://localhost:3002"

def test_api_key_functionality():
    """Test API key save and retrieve functionality"""
    print("🧪 Testing API Key Functionality")
    print("=" * 50)
    
    # Test guest authentication first
    print("\n1. Testing Guest Authentication:")
    try:
        response = requests.get(f"{BASE_URL}/auth/guest")
        if response.status_code == 200:
            print("✅ Guest auth successful")
            # Get the session cookie
            cookies = response.cookies
        else:
            print(f"❌ Guest auth failed: {response.status_code}")
            return
    except Exception as e:
        print(f"❌ Guest auth error: {e}")
        return
    
    # Test saving an API key
    print("\n2. Testing API Key Save:")
    try:
        test_key_data = {
            "service": "gemini",
            "api_key": "test_gemini_key_12345"
        }
        
        response = requests.post(
            f"{BASE_URL}/api/user/api-keys",
            json=test_key_data,
            cookies=cookies
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ API key save successful: {result.get('message', 'Unknown')}")
        else:
            print(f"❌ API key save failed: {response.status_code}")
            print(f"   Response: {response.text}")
    except Exception as e:
        print(f"❌ API key save error: {e}")
    
    # Test listing API keys
    print("\n3. Testing API Key List:")
    try:
        response = requests.get(
            f"{BASE_URL}/api/user/api-keys",
            cookies=cookies
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ API key list successful")
            print(f"   Keys found: {len(result.get('api_keys', []))}")
            for key in result.get('api_keys', []):
                print(f"   - {key.get('service')}: {'Saved' if key.get('has_key') else 'Not saved'}")
        else:
            print(f"❌ API key list failed: {response.status_code}")
            print(f"   Response: {response.text}")
    except Exception as e:
        print(f"❌ API key list error: {e}")
    
    # Test getting a specific API key
    print("\n4. Testing API Key Retrieve:")
    try:
        response = requests.get(
            f"{BASE_URL}/api/user/api-keys/gemini",
            cookies=cookies
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ API key retrieve successful")
            print(f"   Has key: {result.get('has_key', False)}")
        else:
            print(f"❌ API key retrieve failed: {response.status_code}")
            print(f"   Response: {response.text}")
    except Exception as e:
        print(f"❌ API key retrieve error: {e}")
    
    print("\n" + "=" * 50)
    print("🎯 API Key Test Complete!")

if __name__ == "__main__":
    test_api_key_functionality() 