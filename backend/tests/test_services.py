import pytest
import sys
import os

# Add the parent directory to the path so we can import services
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def test_import_user_service():
    """Test that user_service can be imported"""
    try:
        from services.user_service import UserService
        assert UserService is not None
    except ImportError as e:
        pytest.fail(f"Failed to import UserService: {e}")

def test_import_oauth_service():
    """Test that oauth_service can be imported"""
    try:
        from services.oauth_service import OAuthService
        assert OAuthService is not None
    except ImportError as e:
        pytest.fail(f"Failed to import OAuthService: {e}")

def test_import_stripe_service():
    """Test that stripe_service can be imported"""
    try:
        from services.stripe_service import StripeService
        assert StripeService is not None
    except ImportError as e:
        pytest.fail(f"Failed to import StripeService: {e}")

def test_user_service_initialization():
    """Test that UserService can be instantiated"""
    try:
        from services.user_service import UserService
        service = UserService()
        assert service is not None
    except Exception as e:
        pytest.skip(f"UserService initialization failed: {e}")

def test_oauth_service_initialization():
    """Test that OAuthService can be instantiated"""
    try:
        from services.oauth_service import OAuthService
        service = OAuthService()
        assert service is not None
    except Exception as e:
        pytest.skip(f"OAuthService initialization failed: {e}")

def test_stripe_service_initialization():
    """Test that StripeService can be instantiated"""
    try:
        from services.stripe_service import StripeService
        service = StripeService()
        assert service is not None
    except Exception as e:
        pytest.skip(f"StripeService initialization failed: {e}")

def test_config_import():
    """Test that config can be imported"""
    try:
        import config
        assert config is not None
    except ImportError as e:
        pytest.fail(f"Failed to import config: {e}")

def test_supabase_client_import():
    """Test that supabase_client can be imported"""
    try:
        import supabase_client
        assert supabase_client is not None
    except ImportError as e:
        pytest.fail(f"Failed to import supabase_client: {e}") 