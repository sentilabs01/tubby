#!/usr/bin/env python3
"""
Test script to check if Supabase tables exist
"""

import requests
import json

def test_table_exists(table_name):
    """Test if a specific table exists"""
    try:
        # Try to select from the table
        response = requests.get(f'http://localhost:5001/debug/supabase/table/{table_name}', timeout=5)
        if response.status_code == 200:
            print(f"✅ Table '{table_name}' exists")
            return True
        else:
            print(f"❌ Table '{table_name}' does not exist (Status: {response.status_code})")
            return False
    except Exception as e:
        print(f"❌ Error testing table '{table_name}': {e}")
        return False

def main():
    """Test all required tables"""
    print("🔍 Testing Supabase Tables")
    print("=" * 40)
    
    tables = ['users', 'api_keys', 'user_preferences']
    
    for table in tables:
        test_table_exists(table)
    
    print("\n📋 If tables don't exist, run this SQL in Supabase:")
    print("   SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
    print("\n   This will show you what tables currently exist.")

if __name__ == "__main__":
    main() 