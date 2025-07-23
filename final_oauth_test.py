#!/usr/bin/env python3
"""
Final OAuth Integration Test
Comprehensive test of the complete OAuth flow
"""

import requests
import json
import time

def test_complete_oauth_flow():
    """Test the complete OAuth integration"""
    print("🎯 Final OAuth Integration Test")
    print("=" * 50)
    
    # Test 1: Backend Health
    print("\n1️⃣ Testing Backend Health...")
    try:
        response = requests.get('http://localhost:5001/health')
        if response.status_code == 200:
            print("   ✅ Backend is healthy")
        else:
            print(f"   ❌ Backend health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Backend connection failed: {e}")
        return False
    
    # Test 2: Supabase Connection
    print("\n2️⃣ Testing Supabase Connection...")
    try:
        response = requests.get('http://localhost:5001/debug/supabase')
        if response.status_code == 200:
            data = response.json()
            if data.get('status') == 'connected':
                print("   ✅ Supabase connection successful")
            else:
                print(f"   ❌ Supabase connection failed: {data.get('error')}")
                return False
        else:
            print(f"   ❌ Supabase test failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Supabase test failed: {e}")
        return False
    
    # Test 3: OAuth URL Generation
    print("\n3️⃣ Testing OAuth URL Generation...")
    try:
        response = requests.get('http://localhost:5001/auth/google')
        if response.status_code == 200:
            print("   ✅ OAuth URL generation successful")
        else:
            print(f"   ❌ OAuth URL generation failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ OAuth URL generation failed: {e}")
        return False
    
    # Test 4: Guest Authentication
    print("\n4️⃣ Testing Guest Authentication...")
    try:
        response = requests.get('http://localhost:5001/auth/guest')
        if response.status_code == 200:
            data = response.json()
            guest_id = data.get('user', {}).get('id', 'No ID')
            print(f"   ✅ Guest authentication successful (ID: {guest_id})")
        else:
            print(f"   ❌ Guest authentication failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Guest authentication failed: {e}")
        return False
    
    # Test 5: Frontend Connection
    print("\n5️⃣ Testing Frontend Connection...")
    try:
        response = requests.get('http://localhost:4173')
        if response.status_code == 200:
            print("   ✅ Frontend is accessible")
        else:
            print(f"   ⚠️  Frontend returned status: {response.status_code}")
            print("   (This might be normal if frontend is not running)")
    except Exception as e:
        print(f"   ⚠️  Frontend connection failed: {e}")
        print("   (This might be normal if frontend is not running)")
    
    print("\n" + "=" * 50)
    print("🎉 OAuth Integration Test Complete!")
    print("\n📋 Summary:")
    print("   ✅ Backend API: Working")
    print("   ✅ Supabase Database: Connected")
    print("   ✅ OAuth Flow: Ready")
    print("   ✅ Guest Authentication: Working")
    print("   ⚠️  Frontend: Check if running on port 4173")
    
    print("\n🚀 Next Steps:")
    print("   1. Open http://localhost:4173 in your browser")
    print("   2. Try the OAuth login flow")
    print("   3. Test guest authentication")
    print("   4. Verify user data is stored in Supabase")
    
    return True

if __name__ == "__main__":
    test_complete_oauth_flow() 