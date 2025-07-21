#!/usr/bin/env python3
"""
Simple test file that can run without pytest
This ensures CI passes even if pytest is not installed
"""
import sys
import os

# Add the current directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_imports():
    """Test that all modules can be imported"""
    try:
        import app
        print("✅ app module imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import app: {e}")
        return False
    
    try:
        import config
        print("✅ config module imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import config: {e}")
        return False
    
    try:
        import supabase_client
        print("✅ supabase_client module imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import supabase_client: {e}")
        return False
    
    try:
        from services import user_service, oauth_service, stripe_service
        print("✅ services modules imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import services: {e}")
        return False
    
    return True

def test_app_creation():
    """Test that the Flask app can be created"""
    try:
        from app import app
        assert app is not None
        print("✅ Flask app created successfully")
        return True
    except Exception as e:
        print(f"❌ Failed to create Flask app: {e}")
        return False

def test_config_values():
    """Test that config has required values"""
    try:
        from app import app
        assert 'SECRET_KEY' in app.config
        print("✅ App config has SECRET_KEY")
        return True
    except Exception as e:
        print(f"❌ Config test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🧪 Running Simple Tests...")
    print("=" * 40)
    
    tests = [
        test_imports,
        test_app_creation,
        test_config_values
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
        print()
    
    print(f"📊 Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("✅ All tests passed!")
        return 0
    else:
        print("❌ Some tests failed!")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 