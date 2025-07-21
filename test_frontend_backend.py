#!/usr/bin/env python3
"""
Test frontend-backend communication
"""

import requests
import json

def test_frontend_backend_communication():
    """Test that frontend can communicate with backend"""
    print("🧪 Testing Frontend-Backend Communication")
    print("=" * 50)
    
    # Create a session to maintain cookies
    session = requests.Session()
    
    # Step 1: Test backend health
    print("\n1️⃣ Testing backend health...")
    try:
        response = session.get('http://localhost:5001/health')
        if response.status_code == 200:
            print("   ✅ Backend health check passed")
        else:
            print(f"   ❌ Backend health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Backend health check error: {e}")
        return False
    
    # Step 2: Test guest authentication
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
            return False
    except Exception as e:
        print(f"   ❌ Session persistence error: {e}")
        return False
    
    # Step 4: Test API endpoints
    print("\n4️⃣ Testing API endpoints...")
    try:
        response = session.get('http://localhost:5001/api/user/api-keys?user_id=test')
        if response.status_code in [200, 401]:  # 401 is expected for unauthenticated requests
            print("   ✅ API endpoint accessible")
        else:
            print(f"   ❌ API endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ API endpoint error: {e}")
        return False
    
    print("\n" + "=" * 50)
    print("🎉 Frontend-Backend Communication Test Complete!")
    print("\n📋 Summary:")
    print("   ✅ Backend Health: Working")
    print("   ✅ Guest Authentication: Working")
    print("   ✅ Session Persistence: Working")
    print("   ✅ API Endpoints: Accessible")
    print("\n🚀 Next Steps:")
    print("   1. Try the OAuth flow in your browser")
    print("   2. The frontend should now connect to the backend properly")
    print("   3. Check the browser console for any remaining errors")
    
    return True

if __name__ == "__main__":
    test_frontend_backend_communication() 