#!/usr/bin/env python3
"""
Fix CORS Configuration Script
This script fixes the merge conflicts and CORS configuration in backend/app.py
"""

import re
import os

def fix_cors_configuration():
    """Fix the CORS configuration in backend/app.py"""
    
    backend_file = "backend/app.py"
    
    if not os.path.exists(backend_file):
        print("❌ backend/app.py not found")
        return False
    
    # Read the current file
    with open(backend_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Define the new CORS configuration
    new_cors_config = '''# Configure CORS
CORS(app, origins=[
    'http://localhost:3001', 'http://localhost:3003', 'http://localhost:3010', 
    'http://localhost:3015', 'http://localhost:4173',
    'https://tubbyai.com', 'https://www.tubbyai.com',
    'https://your-amplify-domain.amplifyapp.com',  # Add your Amplify domain
    'https://your-eb-environment.elasticbeanstalk.com',  # Add your EB domain
    'https://accounts.google.com', 'https://oauthchooseaccount.google.com'
], supports_credentials=True, methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])

socketio = SocketIO(app, cors_allowed_origins=[
    'http://localhost:3001', 'http://localhost:3003', 'http://localhost:3010', 
    'http://localhost:3015', 'http://localhost:4173',
    'https://tubbyai.com', 'https://www.tubbyai.com',
    'https://your-amplify-domain.amplifyapp.com',  # Add your Amplify domain
    'https://your-eb-environment.elasticbeanstalk.com',  # Add your EB domain
    'https://accounts.google.com', 'https://oauthchooseaccount.google.com'
], async_mode="threading")  # avoid eventlet conflicts on Windows'''
    
    # Find and replace the CORS configuration
    # Look for the pattern that includes merge conflict markers
    cors_pattern = r'# Configure CORS\s*<<<<<<< HEAD.*?=======.*?>>>>>>> [a-f0-9]+'
    
    if re.search(cors_pattern, content, re.DOTALL):
        # Replace the merge conflict section
        content = re.sub(cors_pattern, new_cors_config, content, flags=re.DOTALL)
        print("✅ Fixed merge conflict in CORS configuration")
    else:
        # Look for existing CORS configuration to replace
        cors_simple_pattern = r'CORS\(app, origins=.*?\), supports_credentials=True, methods=\[.*?\]\)'
        if re.search(cors_simple_pattern, content, re.DOTALL):
            # Replace existing CORS configuration
            content = re.sub(cors_simple_pattern, new_cors_config, content, flags=re.DOTALL)
            print("✅ Updated existing CORS configuration")
        else:
            # Look for the line after CORS comment
            cors_comment_pattern = r'(# Configure CORS\s*)\n.*?socketio = SocketIO'
            if re.search(cors_comment_pattern, content, re.DOTALL):
                content = re.sub(cors_comment_pattern, new_cors_config + '\n\n', content, flags=re.DOTALL)
                print("✅ Added new CORS configuration")
            else:
                print("⚠️ Could not find CORS configuration to replace")
                return False
    
    # Write the updated content back
    with open(backend_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ CORS configuration updated successfully")
    return True

def update_session_config():
    """Update session configuration for production"""
    
    backend_file = "backend/app.py"
    
    if not os.path.exists(backend_file):
        print("❌ backend/app.py not found")
        return False
    
    # Read the current file
    with open(backend_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Define the new session configuration
    new_session_config = '''app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
app.config["SESSION_COOKIE_SAMESITE"] = "None"
app.config["SESSION_COOKIE_SECURE"] = True
app.config["SESSION_COOKIE_DOMAIN"] = None  # Let Flask handle domain
app.config["SESSION_COOKIE_HTTPONLY"] = True

# Force development mode for local testing
os.environ['FLASK_ENV'] = 'development' '''
    
    # Find and replace session configuration
    session_pattern = r"app\.config\['SECRET_KEY'\] = os\.getenv\('SECRET_KEY', 'dev-secret-key'\)\s*app\.config\[\"SESSION_COOKIE_SAMESITE\"\] = \"None\"\s*app\.config\[\"SESSION_COOKIE_SECURE\"\]\s*=\s*True"
    
    if re.search(session_pattern, content, re.DOTALL):
        content = re.sub(session_pattern, new_session_config, content, flags=re.DOTALL)
        print("✅ Updated session configuration")
    else:
        print("⚠️ Could not find session configuration to update")
    
    # Write the updated content back
    with open(backend_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

def main():
    """Main function to fix CORS and session configuration"""
    print("🔧 Fixing CORS and Session Configuration")
    print("=" * 50)
    
    # Fix CORS configuration
    if fix_cors_configuration():
        print("✅ CORS configuration fixed")
    else:
        print("❌ Failed to fix CORS configuration")
        return False
    
    # Update session configuration
    if update_session_config():
        print("✅ Session configuration updated")
    else:
        print("❌ Failed to update session configuration")
        return False
    
    print("\n🎉 Configuration fixes completed!")
    print("\n📋 Next steps:")
    print("1. Update your actual domain URLs in the CORS configuration")
    print("2. Deploy the backend: .\\deploy-backend-eb.ps1")
    print("3. Update environment variables in AWS Console")
    print("4. Test the OAuth flow")
    
    return True

if __name__ == "__main__":
    main() 