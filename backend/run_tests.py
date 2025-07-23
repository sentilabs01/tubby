#!/usr/bin/env python3
"""
Simple test runner for the Tubby AI backend
"""
import subprocess
import sys
import os

def run_tests():
    """Run the test suite"""
    print("🧪 Running Tubby AI Backend Tests...")
    print("=" * 50)
    
    # Change to the backend directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    try:
        # Run pytest with coverage
        result = subprocess.run([
            sys.executable, "-m", "pytest",
            "--cov=.",
            "--cov-report=term-missing",
            "--cov-report=html",
            "--verbose",
            "tests/"
        ], capture_output=True, text=True)
        
        print(result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr)
        
        if result.returncode == 0:
            print("\n✅ All tests passed!")
        else:
            print(f"\n❌ Tests failed with exit code {result.returncode}")
            
        return result.returncode
        
    except Exception as e:
        print(f"❌ Error running tests: {e}")
        return 1

if __name__ == "__main__":
    exit_code = run_tests()
    sys.exit(exit_code) 