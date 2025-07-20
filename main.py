import os
import sys
# DON'T CHANGE THIS !!!
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from flask import Flask, send_from_directory
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from src.models.user import db
from src.routes.user import user_bp
from src.routes.terminal import terminal_bp
import docker
import subprocess
import threading
import time

app = Flask(__name__, static_folder=os.path.join(os.path.dirname(__file__), 'static'))
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')

# Enable CORS for all routes
CORS(app, origins="*")

# Initialize SocketIO
socketio = SocketIO(app, cors_allowed_origins="*")

app.register_blueprint(user_bp, url_prefix='/api')
app.register_blueprint(terminal_bp, url_prefix='/api')

# uncomment if you need to use database
app.config['SQLALCHEMY_DATABASE_URI'] = f"sqlite:///{os.path.join(os.path.dirname(__file__), 'database', 'app.db')}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db.init_app(app)
with app.app_context():
    db.create_all()

# Docker client for container management
docker_client = docker.from_env()

# Store active terminal sessions
active_sessions = {}

@socketio.on('connect')
def handle_connect():
    print('Client connected')
    emit('status', {'message': 'Connected to AI Agent Platform'})

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('execute_command')
def handle_execute_command(data):
    terminal_id = data.get('terminal_id', 'terminal1')
    command = data.get('command', '')
    
    print(f"Executing command in {terminal_id}: {command}")
    
    # Route command to appropriate container or local shell
    if command.startswith('claude'):
        # Route to Claude Code container
        try:
            container = docker_client.containers.get('claude-code-instance')
            result = container.exec_run(command, stdout=True, stderr=True)
            output = result.output.decode('utf-8')
            emit('command_output', {
                'terminal_id': terminal_id,
                'command': command,
                'output': output,
                'type': 'claude'
            })
        except Exception as e:
            emit('command_output', {
                'terminal_id': terminal_id,
                'command': command,
                'output': f"Error: {str(e)}",
                'type': 'error'
            })
    elif command.startswith('gemini'):
        # Route to Gemini CLI container
        try:
            container = docker_client.containers.get('gemini-cli-instance')
            result = container.exec_run(command, stdout=True, stderr=True)
            output = result.output.decode('utf-8')
            emit('command_output', {
                'terminal_id': terminal_id,
                'command': command,
                'output': output,
                'type': 'gemini'
            })
        except Exception as e:
            emit('command_output', {
                'terminal_id': terminal_id,
                'command': command,
                'output': f"Error: {str(e)}",
                'type': 'error'
            })
    else:
        # Execute in local shell
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
            output = result.stdout + result.stderr
            emit('command_output', {
                'terminal_id': terminal_id,
                'command': command,
                'output': output,
                'type': 'shell'
            })
        except subprocess.TimeoutExpired:
            emit('command_output', {
                'terminal_id': terminal_id,
                'command': command,
                'output': "Command timed out after 30 seconds",
                'type': 'error'
            })
        except Exception as e:
            emit('command_output', {
                'terminal_id': terminal_id,
                'command': command,
                'output': f"Error: {str(e)}",
                'type': 'error'
            })

@socketio.on('get_container_status')
def handle_get_container_status():
    try:
        claude_container = docker_client.containers.get('claude-code-instance')
        gemini_container = docker_client.containers.get('gemini-cli-instance')
        
        emit('container_status', {
            'claude': {
                'status': claude_container.status,
                'name': claude_container.name
            },
            'gemini': {
                'status': gemini_container.status,
                'name': gemini_container.name
            }
        })
    except Exception as e:
        emit('container_status', {
            'error': str(e)
        })

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve(path):
    static_folder_path = app.static_folder
    if static_folder_path is None:
            return "Static folder not configured", 404

    if path != "" and os.path.exists(os.path.join(static_folder_path, path)):
        return send_from_directory(static_folder_path, path)
    else:
        index_path = os.path.join(static_folder_path, 'index.html')
        if os.path.exists(index_path):
            return send_from_directory(static_folder_path, 'index.html')
        else:
            return "index.html not found", 404


if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)

