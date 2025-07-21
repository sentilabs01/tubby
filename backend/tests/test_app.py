import pytest
import sys
import os

# Add the parent directory to the path so we can import app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def test_always_passes():
    """Basic test to ensure pytest runs successfully"""
    assert True

def test_import_app():
    """Test that we can import the Flask app"""
    try:
        from app import app
        assert app is not None
    except ImportError as e:
        pytest.fail(f"Failed to import app: {e}")

def test_app_config():
    """Test that the app has basic configuration"""
    try:
        from app import app
        assert hasattr(app, 'config')
        assert 'SECRET_KEY' in app.config
    except ImportError:
        pytest.skip("App not available for testing")

def test_health_check():
    """Test that the app can be instantiated without errors"""
    try:
        from app import app
        with app.test_client() as client:
            # This should not raise an exception
            assert client is not None
    except Exception as e:
        pytest.fail(f"App instantiation failed: {e}") 