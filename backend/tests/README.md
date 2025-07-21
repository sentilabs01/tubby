# Backend Tests

This directory contains tests for the Tubby AI backend Flask application.

## Test Structure

- `test_app.py` - Tests for the Flask application and basic functionality
- `test_services.py` - Tests for service modules (UserService, OAuthService, StripeService)
- `test_routes.py` - Tests for Flask routes and API endpoints

## Running Tests

### Option 1: Simple Tests (No pytest required)
```bash
cd backend
python test_simple.py
```

### Option 2: Full pytest Suite (Requires pytest installation)
```bash
cd backend
pip install pytest pytest-cov pytest-flask
python -m pytest --cov=. --cov-report=term-missing
```

### Option 3: Using the test runner script
```bash
cd backend
python run_tests.py
```

## CI/CD Integration

The CI pipeline runs tests using:
```bash
cd backend
python -m pytest --cov=. --cov-report=xml
```

## Test Coverage

Tests cover:
- ✅ Module imports and initialization
- ✅ Flask app creation and configuration
- ✅ Service class instantiation
- ✅ Basic route functionality
- ✅ Error handling

## Adding New Tests

1. Create test files with the prefix `test_`
2. Use descriptive test function names starting with `test_`
3. Add docstrings explaining what each test does
4. Use pytest fixtures for common setup
5. Handle import errors gracefully with `pytest.skip()`

## Example Test Structure

```python
import pytest

def test_functionality():
    """Test description"""
    try:
        # Test code here
        assert True
    except ImportError:
        pytest.skip("Module not available")
    except Exception as e:
        pytest.fail(f"Test failed: {e}")
``` 