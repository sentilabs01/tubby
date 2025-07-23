#!/usr/bin/env python3
"""
Production startup script for Tubby AI Backend
Handles environment setup and Gunicorn server startup
"""

import os
import sys
import subprocess
import signal
import time
from pathlib import Path

def setup_environment():
    """Setup production environment variables"""
    print("🔧 Setting up production environment...")
    
    # Ensure we're in the backend directory
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)
    
    # Load environment variables
    env_file = backend_dir / '.env'
    if env_file.exists():
        print(f"📄 Loading environment from {env_file}")
        from dotenv import load_dotenv
        load_dotenv(env_file)
    
    # Set production defaults
    os.environ.setdefault('FLASK_ENV', 'production')
    os.environ.setdefault('PORT', '5004')
    os.environ.setdefault('HOST', '0.0.0.0')
    
    # Validate required environment variables
    required_vars = [
        'SUPABASE_URL',
        'SUPABASE_ANON_KEY',
        'SECRET_KEY'
    ]
    
    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        print(f"❌ Missing required environment variables: {', '.join(missing_vars)}")
        print("Please set these variables in your .env file or environment")
        return False
    
    print("✅ Environment setup complete")
    return True

def check_dependencies():
    """Check if all required dependencies are installed"""
    print("🔍 Checking dependencies...")
    
    try:
        import flask
        import flask_socketio
        import gunicorn
        import eventlet
        print("✅ All dependencies found")
        return True
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        return False

def start_gunicorn():
    """Start the Gunicorn server"""
    print("🚀 Starting Gunicorn server...")
    
    # Gunicorn command
    cmd = [
        'gunicorn',
        '--config', 'gunicorn.conf.py',
        '--worker-class', 'eventlet',
        '--workers', str(os.getenv('GUNICORN_WORKERS', '4')),
        '--bind', f"0.0.0.0:{os.getenv('PORT', '5004')}",
        '--timeout', '30',
        '--keep-alive', '2',
        '--max-requests', '1000',
        '--max-requests-jitter', '50',
        '--preload',
        'app:app'
    ]
    
    print(f"📋 Command: {' '.join(cmd)}")
    
    try:
        # Start the server
        process = subprocess.Popen(cmd)
        
        # Wait for the process
        process.wait()
        
    except KeyboardInterrupt:
        print("\n🛑 Received interrupt signal, shutting down...")
        if process:
            process.terminate()
            process.wait()
    except Exception as e:
        print(f"❌ Error starting server: {e}")
        return False
    
    return True

def health_check():
    """Perform a health check on the application"""
    print("🏥 Performing health check...")
    
    try:
        import requests
        import time
        
        # Wait a bit for the server to start
        time.sleep(2)
        
        response = requests.get(f"http://localhost:{os.getenv('PORT', '5004')}/health", timeout=5)
        
        if response.status_code == 200:
            print("✅ Health check passed")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def main():
    """Main startup function"""
    print("🚀 Tubby AI Backend Production Startup")
    print("=" * 50)
    
    # Setup environment
    if not setup_environment():
        sys.exit(1)
    
    # Check dependencies
    if not check_dependencies():
        print("❌ Dependency check failed")
        sys.exit(1)
    
    # Start the server
    if not start_gunicorn():
        print("❌ Failed to start server")
        sys.exit(1)
    
    print("✅ Server shutdown complete")

if __name__ == '__main__':
    main() 