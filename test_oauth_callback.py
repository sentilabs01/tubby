#!/usr/bin/env python3
"""
Test OAuth callback flow
"""

import requests
import json

def test_oauth_callback():
    """Test the OAuth callback flow"""
    print("🧪 Testing OAuth Callback Flow")
    print("=" * 50)
    
    # Create a session to maintain cookies
    session = requests.Session()
    
    # Step 1: Test the callback page
    print("\n1️⃣ Testing OAuth callback page...")
    try:
        response = session.get('http://localhost:5001/auth/callback')
        if response.status_code == 200:
            print("   ✅ Callback page accessible")
            print(f"   Content length: {len(response.text)}")
            if 'localhost:3015' in response.text:
                print("   ✅ Callback page contains correct frontend URL")
            else:
                print("   ❌ Callback page missing correct frontend URL")
        else:
            print(f"   ❌ Callback page failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Callback page error: {e}")
        return False
    
    # Step 2: Test guest auth to simulate session
    print("\n2️⃣ Testing guest authentication...")
    try:
        response = session.get('http://localhost:5001/auth/guest')
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Guest auth successful: {data.get('user', {}).get('id')}")
        else:
            print(f"   ❌ Guest auth failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Guest auth error: {e}")
        return False
    
    # Step 3: Test session after guest auth
    print("\n3️⃣ Testing session after guest auth...")
    try:
        response = session.get('http://localhost:5001/auth/user')
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Session working: {data.get('user', {}).get('id')}")
        else:
            print(f"   ❌ Session failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ Session error: {e}")
        return False
    
    print("\n" + "=" * 50)
    print("🎉 OAuth Callback Test Complete!")
    print("\n📋 Summary:")
    print("   ✅ Callback Page: Accessible")
    print("   ✅ Guest Auth: Working")
    print("   ✅ Session: Working")
    print("\n🚀 Next Steps:")
    print("   1. Try OAuth login in browser")
    print("   2. Check if session is maintained")
    print("   3. Look for any console errors")
    
    return True

if __name__ == "__main__":
    test_oauth_callback() 