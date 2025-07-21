#!/usr/bin/env python3
"""
Test OAuth URL generation with correct port
"""

import os
import sys
from dotenv import load_dotenv

# Add backend to path
sys.path.append('backend')

from services.oauth_service import OAuthService

def test_oauth_url():
    """Test OAuth URL generation"""
    print("🧪 Testing OAuth URL Generation")
    print("=" * 50)
    
    # Set the frontend URL explicitly
    os.environ['FRONTEND_URL'] = 'http://localhost:3015'
    
    # Initialize OAuth service
    oauth_service = OAuthService()
    
    # Generate OAuth URL
    try:
        auth_url = oauth_service.get_supabase_auth_url('google')
        if auth_url:
            print(f"✅ OAuth URL generated successfully")
            print(f"URL: {auth_url}")
            
            # Check if the redirect URL contains the correct port
            if 'localhost:3003' in auth_url:
                print("✅ Redirect URL contains correct port (3003)")
            else:
                print("❌ Redirect URL does not contain correct port")
                print(f"Expected: localhost:3003")
                print(f"Found: {auth_url}")
        else:
            print("❌ Failed to generate OAuth URL")
    except Exception as e:
        print(f"❌ Error generating OAuth URL: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    load_dotenv()
    test_oauth_url() 