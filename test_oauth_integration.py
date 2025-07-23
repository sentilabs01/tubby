#!/usr/bin/env python3
"""
Test script for OAuth integration troubleshooting
"""

import requests
import json
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_backend_health():
    """Test if backend is running"""
    try:
        response = requests.get('http://localhost:5001/health')
        print(f"✅ Backend health check: {response.status_code}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Backend health check failed: {e}")
        return False

def test_supabase_connection():
    """Test Supabase connection"""
    try:
        response = requests.get('http://localhost:5001/debug/supabase')
        print(f"✅ Supabase connection test: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Supabase URL: {data.get('url', 'Not configured')}")
            print(f"   Connection: {data.get('status', 'Unknown')}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Supabase connection test failed: {e}")
        return False

def test_oauth_url_generation():
    """Test OAuth URL generation"""
    try:
        response = requests.get('http://localhost:5001/auth/google')
        print(f"✅ OAuth URL generation: {response.status_code}")
        if response.status_code == 302:  # Redirect
            print(f"   Redirect URL: {response.headers.get('Location', 'No redirect')}")
        return response.status_code in [200, 302]
    except Exception as e:
        print(f"❌ OAuth URL generation failed: {e}")
        return False

def test_guest_auth():
    """Test guest authentication"""
    try:
        response = requests.get('http://localhost:5001/auth/guest')
        print(f"✅ Guest auth test: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Guest user created: {data.get('user', {}).get('id', 'No ID')}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Guest auth test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🔍 OAuth Integration Troubleshooting Tests")
    print("=" * 50)
    
    tests = [
        ("Backend Health", test_backend_health),
        ("Supabase Connection", test_supabase_connection),
        ("OAuth URL Generation", test_oauth_url_generation),
        ("Guest Authentication", test_guest_auth),
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n🧪 Testing: {test_name}")
        result = test_func()
        results.append((test_name, result))
    
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"   {test_name}: {status}")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    print(f"\n🎯 Overall: {passed}/{total} tests passed")
    
    if passed < total:
        print("\n🔧 Troubleshooting Steps:")
        print("1. Check if backend is running on port 5001")
        print("2. Verify Supabase configuration in config.py")
        print("3. Check environment variables")
        print("4. Review backend logs for detailed error messages")
        print("5. Ensure database schema is properly set up")

if __name__ == "__main__":
    main() 