from flask import Flask, render_template, request, jsonify, redirect, session
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import requests
import os
import re
import json
import time
from datetime import datetime
from dotenv import load_dotenv
import tempfile
import subprocess
from supabase_client import supabase_manager
from services.oauth_service import OAuthService
from services.user_service import UserService
from services.stripe_service import StripeService
import shutil
from pathlib import Path
import platform

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

# Configure CORS for production - allow all origins for now
CORS(app, origins=['*'], supports_credentials=True, methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])

socketio = SocketIO(app, cors_allowed_origins=['*'], async_mode="threading")

# Container endpoints
GEMINI_CLI_URL_1 = os.getenv('GEMINI_CLI_URL_1', 'http://localhost:8001')
GEMINI_CLI_URL_2 = os.getenv('GEMINI_CLI_URL_2', 'http://localhost:8002')

# Initialize authentication services
print("🔧 Initializing OAuth service...")
oauth_service = OAuthService()
user_service = UserService()
stripe_service = StripeService()

print("✅ Backend services initialized")

@app.route('/')
def index():
    return jsonify({"message": "Tubby AI Backend is running!", "status": "healthy"})

@app.route('/health')
def health_check():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    })

@app.route('/test')
def test_endpoint():
    return jsonify({"message": "Test endpoint working!"})

@app.route('/auth/user')
def get_current_user():
    """Get current user from session"""
    try:
        user_id = session.get('user_id')
        if not user_id:
            return jsonify({"error": "No user session"}), 401
        
        # Get user from Supabase
        user = user_service.get_user_by_id(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        return jsonify({
            "user": {
                "id": user.get('id'),
                "email": user.get('email'),
                "name": user.get('name'),
                "avatar_url": user.get('avatar_url'),
                "subscription_status": user.get('subscription_status', 'basic')
            }
        })
    except Exception as e:
        print(f"Error getting current user: {e}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/auth/guest', methods=['GET', 'POST'])
def guest_auth():
    """Guest authentication endpoint"""
    try:
        if request.method == 'POST':
            data = request.get_json()
            guest_name = data.get('name', 'Guest User')
            
            # Create guest user session
            session['user_id'] = f"guest_{int(time.time())}"
            session['user_type'] = 'guest'
            session['guest_name'] = guest_name
            
            return jsonify({
                "user": {
                    "id": session['user_id'],
                    "name": guest_name,
                    "type": "guest",
                    "subscription_status": "basic"
                }
            })
        else:
            # Check if guest session exists
            if session.get('user_type') == 'guest':
                return jsonify({
                    "user": {
                        "id": session.get('user_id'),
                        "name": session.get('guest_name', 'Guest User'),
                        "type": "guest",
                        "subscription_status": "basic"
                    }
                })
            return jsonify({"error": "No guest session"}), 401
    except Exception as e:
        print(f"Error in guest auth: {e}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/auth/logout')
def logout():
    """Logout endpoint"""
    try:
        session.clear()
        return jsonify({"message": "Logged out successfully"})
    except Exception as e:
        print(f"Error in logout: {e}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/api/containers/status')
def get_container_status():
    """Get status of AI containers"""
    try:
        containers = {}
        
        # Check Gemini CLI containers
        for i, url in enumerate([GEMINI_CLI_URL_1, GEMINI_CLI_URL_2], 1):
            try:
                response = requests.get(f"{url}/health", timeout=5)
                containers[f"gemini-cli-{i}"] = {
                    "status": "running" if response.status_code == 200 else "error",
                    "url": url
                }
            except requests.exceptions.RequestException:
                containers[f"gemini-cli-{i}"] = {
                    "status": "offline",
                    "url": url
                }
        
        return jsonify({"containers": containers})
    except Exception as e:
        print(f"Error getting container status: {e}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/api/mcp/communicate', methods=['POST'])
def mcp_communicate():
    """Communicate with MCP containers"""
    try:
        data = request.get_json()
        container_url = data.get('container_url')
        message = data.get('message')
        
        if not container_url or not message:
            return jsonify({"error": "Missing container_url or message"}), 400
        
        response = requests.post(
            f"{container_url}/mcp",
            json={"message": message},
            timeout=30
        )
        
        return jsonify(response.json())
    except requests.exceptions.Timeout:
        return jsonify({"error": "Request timed out"}), 408
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Container communication error: {str(e)}"}), 500
    except Exception as e:
        print(f"Error in MCP communication: {e}")
        return jsonify({"error": "Internal server error"}), 500

# WebSocket events
@socketio.on('connect')
def handle_connect():
    print(f"Client connected: {request.sid}")
    emit('connected', {'message': 'Connected to Tubby AI Backend'})

@socketio.on('disconnect')
def handle_disconnect():
    print(f"Client disconnected: {request.sid}")

@socketio.on('get_container_status')
def handle_get_container_status():
    """WebSocket handler for container status"""
    try:
        containers = {}
        
        # Check Gemini CLI containers
        for i, url in enumerate([GEMINI_CLI_URL_1, GEMINI_CLI_URL_2], 1):
            try:
                response = requests.get(f"{url}/health", timeout=5)
                containers[f"gemini-cli-{i}"] = {
                    "status": "running" if response.status_code == 200 else "error",
                    "url": url
                }
            except requests.exceptions.RequestException:
                containers[f"gemini-cli-{i}"] = {
                    "status": "offline",
                    "url": url
                }
        
        emit('container_status', containers)
    except Exception as e:
        print(f"Error in WebSocket container status: {e}")
        emit('error', {'message': 'Failed to get container status'})

@socketio.on('mcp_function')
def handle_mcp_function(data):
    """WebSocket handler for MCP function calls"""
    try:
        container_url = data.get('container_url')
        function_name = data.get('function_name')
        params = data.get('params', {})
        
        if not container_url or not function_name:
            emit('error', {'message': 'Missing container_url or function_name'})
            return
        
        response = requests.post(
            f"{container_url}/mcp/function",
            json={
                "function_name": function_name,
                "params": params
            },
            timeout=30
        )
        
        emit('mcp_response', response.json())
    except requests.exceptions.Timeout:
        emit('error', {'message': 'Request timed out'})
    except requests.exceptions.RequestException as e:
        emit('error', {'message': f'Container communication error: {str(e)}'})
    except Exception as e:
        print(f"Error in WebSocket MCP function: {e}")
        emit('error', {'message': 'Internal server error'})

@socketio.on('execute_command')
def handle_command(data):
    """WebSocket handler for command execution"""
    try:
        command = data.get('command')
        terminal_type = data.get('terminal', 'system')
        
        if not command:
            emit('error', {'message': 'No command provided'})
            return
        
        # For now, just echo the command back
        emit('command_output', {
            'output': f'Command received: {command}',
            'error': '',
            'terminal': terminal_type
        })
        
    except Exception as e:
        print(f"Error in WebSocket command execution: {e}")
        emit('error', {'message': 'Internal server error'})

# Debug: Print all registered routes
print("🔍 Registered routes:")
for rule in app.url_map.iter_rules():
    print(f"  {rule.rule} -> {rule.endpoint}")

if __name__ == '__main__':
    # Read host/port from environment
    try:
        port = int(os.getenv('PORT', '5004'))
    except ValueError:
        port = 5004
    
    host = os.getenv('HOST', '0.0.0.0')
    print(f"Starting server on {host}:{port}")
    socketio.run(app, host=host, port=port, debug=False, allow_unsafe_werkzeug=True) 