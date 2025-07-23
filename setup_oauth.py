#!/usr/bin/env python3
"""
OAuth Integration Setup Script
This script will fix all OAuth integration issues
"""

import os
import sys
import requests
import json
from pathlib import Path

def create_env_file():
    """Create .env file with proper configuration"""
    env_content = """# Supabase Configuration
SUPABASE_URL=https://ewrbezytnhuovvmkepeg.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3cmJlenl0bmh1b3Z2bWtlcGVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5Njg4MjksImV4cCI6MjA2ODU0NDgyOX0.WagV4Mmud1Co1SvRZ1nCVTLJt7DTIa7KlMqqHcjlHVs

# Flask Configuration
SECRET_KEY=dev-secret-key-change-in-production
FLASK_ENV=development

# Frontend Configuration
FRONTEND_URL=http://localhost:4173

# Redis Configuration (optional for development)
REDIS_HOST=localhost
REDIS_PORT=6379

# Encryption Key (will be auto-generated if not provided)
# ENCRYPTION_KEY=your-encryption-key-here

# JWT Configuration
JWT_SECRET_KEY=your-jwt-secret-key-here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
"""
    
    env_path = Path('.env')
    if not env_path.exists():
        with open(env_path, 'w') as f:
            f.write(env_content)
        print("✅ Created .env file")
    else:
        print("ℹ️  .env file already exists")

def create_supabase_schema():
    """Create the required database schema in Supabase"""
    schema_sql = """
-- Create users table for Supabase Auth and subscription management
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    supabase_id UUID UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    picture TEXT,
    provider VARCHAR(50) DEFAULT 'unknown',
    verified_email BOOLEAN DEFAULT FALSE,
    subscription_status VARCHAR(50) DEFAULT 'free',
    subscription_id VARCHAR(255),
    stripe_customer_id VARCHAR(255),
    subscription_plan VARCHAR(50) DEFAULT 'free',
    subscription_period_end TIMESTAMP WITH TIME ZONE,
    subscription_cancel_at_period_end BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create api_keys table for storing encrypted API keys
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    service TEXT NOT NULL CHECK (service IN ('gemini', 'anthropic', 'openai')),
    encrypted_key TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, service)
);

-- Create user_preferences table for storing user settings
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE,
    theme TEXT DEFAULT 'dark' CHECK (theme IN ('light', 'dark')),
    terminal_font_size INTEGER DEFAULT 14,
    terminal_font_family TEXT DEFAULT 'monospace',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_supabase_id ON users(supabase_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_provider ON users(provider);
CREATE INDEX IF NOT EXISTS idx_users_subscription_status ON users(subscription_status);
CREATE INDEX IF NOT EXISTS idx_users_stripe_customer_id ON users(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_users_subscription_plan ON users(subscription_plan);
CREATE INDEX IF NOT EXISTS idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_service ON api_keys(service);

-- Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Drop existing policies that might be too restrictive
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;

-- Create more permissive policies for OAuth integration
CREATE POLICY "Users can view their own data" ON users
    FOR SELECT USING (auth.uid()::text = supabase_id::text);

CREATE POLICY "Users can update their own data" ON users
    FOR UPDATE USING (auth.uid()::text = supabase_id::text);

CREATE POLICY "Users can insert their own data" ON users
    FOR INSERT WITH CHECK (auth.uid()::text = supabase_id::text);

-- Add a policy to allow service role to manage users (for backend operations)
CREATE POLICY "Service role can manage users" ON users
    FOR ALL USING (auth.role() = 'service_role');

-- Grant necessary permissions to the anon role for OAuth
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL ON users TO anon;
GRANT ALL ON api_keys TO anon;
GRANT ALL ON user_preferences TO anon;

-- Create update trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
"""
    
    # Save schema to file
    schema_path = Path('database/schema_setup.sql')
    schema_path.parent.mkdir(exist_ok=True)
    with open(schema_path, 'w') as f:
        f.write(schema_sql)
    
    print("✅ Created database schema file: database/schema_setup.sql")
    print("📋 Please run this SQL in your Supabase SQL Editor:")
    print(f"   File: {schema_path.absolute()}")

def test_backend_connection():
    """Test if backend is running and accessible"""
    try:
        response = requests.get('http://localhost:5001/health', timeout=5)
        if response.status_code == 200:
            print("✅ Backend is running and accessible")
            return True
        else:
            print(f"❌ Backend returned status code: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Backend connection failed: {e}")
        return False

def test_supabase_after_setup():
    """Test Supabase connection after schema setup"""
    try:
        response = requests.get('http://localhost:5001/debug/supabase', timeout=5)
        if response.status_code == 200:
            data = response.json()
            if data.get('status') == 'connected':
                print("✅ Supabase connection successful")
                return True
            else:
                print(f"❌ Supabase connection failed: {data.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ Supabase test returned status code: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Supabase test failed: {e}")
        return False

def main():
    """Main setup function"""
    print("🔧 OAuth Integration Setup")
    print("=" * 50)
    
    # Step 1: Create .env file
    print("\n1️⃣ Creating environment configuration...")
    create_env_file()
    
    # Step 2: Create database schema
    print("\n2️⃣ Creating database schema...")
    create_supabase_schema()
    
    # Step 3: Test backend connection
    print("\n3️⃣ Testing backend connection...")
    if not test_backend_connection():
        print("❌ Backend is not running. Please start it with:")
        print("   cd backend && python app.py")
        return
    
    # Step 4: Instructions for manual steps
    print("\n4️⃣ Manual Steps Required:")
    print("   📋 Run the SQL schema in your Supabase SQL Editor:")
    print("      File: database/schema_setup.sql")
    print("   🔄 Restart the backend after running the SQL")
    print("   🧪 Test the OAuth integration")
    
    print("\n✅ Setup complete! Follow the manual steps above.")

if __name__ == "__main__":
    main() 