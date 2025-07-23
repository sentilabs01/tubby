from flask import Flask, render_template, request, jsonify, redirect, session, abort
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import requests
import os
import re
import json
import redis
import time
from datetime import datetime
from dotenv import load_dotenv
import tempfile
import subprocess
from supabase_client import supabase_manager
from services.oauth_service import OAuthService
from services.user_service import UserService
from services.stripe_service import StripeService

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
app.config['SESSION_COOKIE_SECURE'] = True  # Enable for production
app.config['SESSION_COOKIE_HTTPONLY'] = True

# Configure CORS for production
CORS(app, origins=[
    'https://tubbyai.com',
    'https://www.tubbyai.com',
    'http://localhost:3001',
    'http://localhost:3003',
    'http://localhost:3010',
    'http://localhost:3015',
    'http://localhost:4173'
], supports_credentials=True, methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])

socketio = SocketIO(app, cors_allowed_origins="*")

# Redis connection - use environment variable for production
redis_url = os.getenv('REDIS_URL', 'redis://localhost:6379')
try:
    redis_client = redis.from_url(redis_url, decode_responses=True)
except Exception as e:
    print(f"Redis connection failed: {e}")
    redis_client = None

# Container endpoints
GEMINI_CLI_URL_1 = os.getenv('GEMINI_CLI_URL_1', 'http://localhost:8001')
GEMINI_CLI_URL_2 = os.getenv('GEMINI_CLI_URL_2', 'http://localhost:8002')

# Initialize authentication services
oauth_service = OAuthService()
user_service = UserService()
stripe_service = StripeService()

# Authentication decorator
def require_auth(f):
    """Decorator to require authentication"""
    def decorated_function(*args, **kwargs):
        # Check for guest user first
        if session.get('is_guest') and session.get('guest_user'):
            request.current_user = session['guest_user']
            return f(*args, **kwargs)
        
        access_token = session.get('access_token') or request.headers.get('Authorization', '').replace('Bearer ', '')
        
        if not access_token:
            return jsonify({'error': 'Authentication required'}), 401
        
        user_data = oauth_service.verify_supabase_token(access_token)
        if not user_data:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # Look up user in database by Supabase ID
        supabase_id = user_data.get('id')
        if not supabase_id:
            return jsonify({'error': 'Invalid user data'}), 401
        
        # Try to find user in database
        user = user_service.get_user_by_supabase_id(supabase_id)
        
        if not user:
            # Create user if not found
            print(f"User not found in database, creating new user: {user_data.get('email', 'Unknown')}")
            user = user_service.create_user_from_oauth(user_data)
            
            if not user:
                return jsonify({'error': 'Failed to create user account'}), 500
        
        # Set the database user record as current user
        request.current_user = user
        return f(*args, **kwargs)
    
    decorated_function.__name__ = f.__name__
    return decorated_function

# Health check endpoint for Amplify
@app.route('/health')
def health_check():
    """Health check endpoint for Amplify monitoring"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'environment': os.getenv('FLASK_ENV', 'development')
    })

# Import all routes from the main app
from app import *

# Production-specific configurations
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5004))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    print(f"Starting production server on port {port}")
    print(f"Debug mode: {debug}")
    print(f"Environment: {os.environ.get('FLASK_ENV', 'production')}")
    
    socketio.run(app, host='0.0.0.0', port=port, debug=debug) 