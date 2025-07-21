#!/usr/bin/env python3
"""
Test the complete OAuth flow
"""

import requests
import json

def test_oauth_flow():
    """Test the complete OAuth flow"""
    print("🧪 Testing Complete OAuth Flow")
    print("=" * 50)
    
    # Create a session to maintain cookies
    session = requests.Session()
    
    # Step 1: Test OAuth URL generation
    print("\n1️⃣ Testing OAuth URL generation...")
    try:
        response = session.get('http://localhost:5001/auth/google')
        if response.status_code == 200:
            print("   ✅ OAuth URL generation successful")
        else:
            print(f"   ❌ OAuth URL generation failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ OAuth URL generation error: {e}")
        return False
    
    # Step 2: Test guest authentication (as fallback)
    print("\n2️⃣ Testing guest authentication...")
    try:
        response = session.get('http://localhost:5001/auth/guest')
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Guest authentication successful: {data.get('user', {}).get('id')}")
        else:
            print(f"   ❌ Guest authentication failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Guest authentication error: {e}")
        return False
    
    # Step 3: Test session persistence
    print("\n3️⃣ Testing session persistence...")
    try:
        response = session.get('http://localhost:5001/auth/user')
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Session persistence successful: {data.get('user', {}).get('id')}")
        else:
            print(f"   ❌ Session persistence failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ Session persistence error: {e}")
        return False
    
    print("\n" + "=" * 50)
    print("🎉 OAuth Flow Test Complete!")
    print("\n📋 Summary:")
    print("   ✅ OAuth URL Generation: Working")
    print("   ✅ Guest Authentication: Working")
    print("   ✅ Session Persistence: Working")
    print("\n🚀 Next Steps:")
    print("   1. Try the OAuth flow in your browser")
    print("   2. Check if the session is maintained")
    print("   3. Verify user data is stored in Supabase")
    
    return True

if __name__ == "__main__":
    test_oauth_flow() 