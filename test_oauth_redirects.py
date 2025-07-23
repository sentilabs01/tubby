#!/usr/bin/env python3
"""
Test script to check OAuth redirect URIs
"""
import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_oauth_configuration():
    """Test OAuth configuration"""
    print("🔍 Testing OAuth Configuration...")
    
    # Check environment variables
    google_client_id = os.getenv('GOOGLE_CLIENT_ID')
    github_client_id = os.getenv('GITHUB_CLIENT_ID')
    frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3001')
    
    print(f"✅ Google Client ID: {google_client_id}")
    print(f"✅ GitHub Client ID: {github_client_id}")
    print(f"✅ Frontend URL: {frontend_url}")
    
    # Expected redirect URIs
    expected_redirects = [
        f"{frontend_url}/auth/callback",
        "https://tubbyai.com/auth/callback",
        "http://localhost:3001/auth/callback"
    ]
    
    print("\n📋 Expected Redirect URIs:")
    for uri in expected_redirects:
        print(f"   - {uri}")
    
    print("\n🔧 To fix redirect_uri_mismatch error:")
    print("1. Go to Google Cloud Console: https://console.cloud.google.com/apis/credentials")
    print("2. Edit your OAuth 2.0 Client ID")
    print("3. Add these to 'Authorized redirect URIs':")
    for uri in expected_redirects:
        print(f"   - {uri}")
    
    print("\n4. Go to GitHub OAuth: https://github.com/settings/developers")
    print("5. Edit your OAuth App")
    print("6. Set 'Authorization callback URL' to:")
    print("   - https://tubbyai.com/auth/callback")

if __name__ == "__main__":
    test_oauth_configuration() 