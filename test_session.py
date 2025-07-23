#!/usr/bin/env python3
"""
Test session handling for OAuth flow
"""

import requests
import json

def test_session_flow():
    """Test the complete session flow"""
    print("🧪 Testing Session Flow")
    print("=" * 40)
    
    # Create a session
    session = requests.Session()
    
    # Step 1: Create a guest user (this should set session)
    print("\n1️⃣ Creating guest user...")
    try:
        response = session.get('http://localhost:5001/auth/guest')
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Guest user created: {data.get('user', {}).get('id')}")
        else:
            print(f"   ❌ Guest creation failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Guest creation error: {e}")
        return False
    
    # Step 2: Check if user is in session
    print("\n2️⃣ Checking session...")
    try:
        response = session.get('http://localhost:5001/auth/user')
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ User in session: {data.get('user', {}).get('id')}")
            return True
        else:
            print(f"   ❌ Session check failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ Session check error: {e}")
        return False

if __name__ == "__main__":
    test_session_flow() 