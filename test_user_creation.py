#!/usr/bin/env python3
"""
Test user creation with Supabase
"""

import os
import sys
from dotenv import load_dotenv

# Add backend to path
sys.path.append('backend')

from services.user_service import UserService
from services.oauth_service import OAuthService

def test_user_creation():
    """Test creating a user directly"""
    print("🧪 Testing User Creation")
    print("=" * 40)
    
    # Initialize services
    user_service = UserService()
    oauth_service = OAuthService()
    
    # Test data with proper UUID format
    test_user_data = {
        'id': '123e4567-e89b-12d3-a456-426614174000',  # Proper UUID format
        'email': 'test@example.com',
        'user_metadata': {
            'full_name': 'Test User',
            'avatar_url': 'https://example.com/avatar.jpg'
        },
        'app_metadata': {
            'provider': 'google'
        },
        'email_confirmed_at': '2025-01-21T00:00:00Z'
    }
    
    print(f"Test user data: {test_user_data}")
    
    # Try to create user
    try:
        result = user_service.create_or_update_user_from_supabase(test_user_data)
        if result:
            print(f"✅ User created successfully: {result}")
        else:
            print("❌ User creation failed")
    except Exception as e:
        print(f"❌ Error creating user: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    load_dotenv()
    test_user_creation() 