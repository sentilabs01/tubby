from flask import Flask, render_template, request, jsonify
from flask_socketio import SocketIO, emit
import requests
import os
import re
import json
import redis
import time
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
socketio = SocketIO(app, cors_allowed_origins="*")

# Redis connection
redis_client = redis.Redis(host='redis', port=6379, decode_responses=True)

# Container endpoints
GEMINI_CLI_URL_1 = "http://gemini-cli-container-1:8001"
GEMINI_CLI_URL_2 = "http://gemini-cli-container-2:8002"

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/containers/status')
def get_container_status():
    """Get status of all containers"""
    status = {
        'gemini-1': 'unknown',
        'gemini-2': 'unknown',
        'redis': 'unknown'
    }
    
    try:
        # Check Gemini CLI Container 1
        response = requests.get(f"{GEMINI_CLI_URL_1}/health", timeout=10)
        if response.status_code == 200:
            status['gemini-1'] = 'running'
    except:
        status['gemini-1'] = 'stopped'
    
    try:
        # Check Gemini CLI Container 2
        response = requests.get(f"{GEMINI_CLI_URL_2}/health", timeout=10)
        if response.status_code == 200:
            status['gemini-2'] = 'running'
    except:
        status['gemini-2'] = 'stopped'
    

    
    try:
        # Check Redis container using ping command
        import subprocess
        result = subprocess.run(['redis-cli', '-h', 'redis', 'ping'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and 'PONG' in result.stdout:
            status['redis'] = 'running'
        else:
            status['redis'] = 'stopped'
    except:
        status['redis'] = 'unknown'
    
    return jsonify(status)

# Add MCP communication endpoint
@app.route('/api/mcp/communicate', methods=['POST'])
def mcp_communicate():
    """Enable cross-terminal communication via MCP"""
    data = request.get_json()
    source_terminal = data.get('source')
    target_terminal = data.get('target')
    message = data.get('message')
    
    if not all([source_terminal, target_terminal, message]):
        return jsonify({'error': 'Missing required fields'}), 400
    
    # Route message to appropriate MCP server
    if target_terminal == 'gemini-1':
        mcp_url = 'http://gemini-cli-container-1:8001/execute'
        command = f'gemini --prompt "{message}"'
    elif target_terminal == 'gemini-2':
        mcp_url = 'http://gemini-cli-container-2:8002/execute'
        command = f'gemini --prompt "{message}"'

    else:
        return jsonify({'error': 'Invalid target terminal'}), 400
    
    try:
        response = requests.post(mcp_url, json={'command': command}, timeout=120)
        result = response.json()
        
        # Broadcast the incoming message to the target terminal UI
        socketio.emit('mcp_message_received', {
            'source': source_terminal,
            'target': target_terminal,
            'message': message,
            'response': result
        })
        
        return jsonify({
            'source': source_terminal,
            'target': target_terminal,
            'message': message,
            'response': result
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/terminals/spawn', methods=['POST'])
def spawn_terminal():
    """Spawn a new Gemini CLI terminal container"""
    import subprocess
    import random
    
    try:
        # Generate a unique port and container name
        base_port = 8000
        used_ports = [8001, 8002]  # Existing ports
        
        # Find next available port
        port = base_port + 3  # Start from 8003
        while port in used_ports:
            port += 1
        
        container_name = f"gemini-cli-container-{port}"
        
        # Build and run the container
        cmd = [
            'docker', 'run', '-d',
            '--name', container_name,
            '--network', 'runmvpwithdockerandrequiredtools_ai-agent-network',
            '-p', f'{port}:{port}',
            '-e', f'GEMINI_API_KEY={os.getenv("GEMINI_API_KEY", "")}',
            '-e', f'MCP_PORT={port}',
            'runmvpwithdockerandrequiredtools-gemini-cli-container-1'  # Use existing image
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            container_id = result.stdout.strip()
            
            # Wait a moment for container to start
            import time
            time.sleep(2)
            
            # Check if container is healthy
            health_cmd = ['docker', 'exec', container_name, 'curl', '-f', f'http://localhost:{port}/health']
            health_result = subprocess.run(health_cmd, capture_output=True, text=True, timeout=30)
            
            if health_result.returncode == 0:
                return jsonify({
                    'success': True,
                    'container_id': container_id,
                    'container_name': container_name,
                    'port': port,
                    'terminal_id': f'gemini-{port}'
                })
            else:
                # Container started but health check failed
                return jsonify({
                    'success': False,
                    'error': 'Container started but health check failed'
                }), 500
        else:
            return jsonify({
                'success': False,
                'error': f'Failed to spawn container: {result.stderr}'
            }), 500
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/terminals/list', methods=['GET'])
def list_terminals():
    """List all running Gemini CLI terminals"""
    import subprocess
    
    try:
        # Get all running gemini containers
        cmd = ['docker', 'ps', '--filter', 'name=gemini-cli-container', '--format', '{{.Names}},{{.Ports}}']
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        terminals = []
        if result.returncode == 0:
            for line in result.stdout.strip().split('\n'):
                if line:
                    parts = line.split(',')
                    if len(parts) == 2:
                        name = parts[0]
                        ports = parts[1]
                        
                        # Extract port number
                        port_match = re.search(r'(\d+):\d+', ports)
                        if port_match:
                            port = int(port_match.group(1))
                            terminal_id = f'gemini-{port}'
                            terminals.append({
                                'name': name,
                                'port': port,
                                'terminal_id': terminal_id
                            })
        
        return jsonify({'terminals': terminals})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Collaborative workspace endpoints
@app.route('/api/workspace/upload', methods=['POST'])
def upload_to_workspace():
    """Upload code/files to the collaborative workspace"""
    try:
        data = request.get_json()
        file_content = data.get('content', '')
        file_name = data.get('name', 'untitled.txt')
        file_type = data.get('type', 'text')
        
        # Store in Redis with metadata
        file_key = f"workspace:file:{file_name}"
        file_data = {
            'name': file_name,
            'content': file_content,
            'type': file_type,
            'uploaded_at': str(datetime.now())
        }
        
        redis_client.set(file_key, json.dumps(file_data))
        
        # Add to workspace index
        workspace_files = redis_client.get('workspace:files')
        if workspace_files:
            files = json.loads(workspace_files)
        else:
            files = []
        
        if file_name not in [f['name'] for f in files]:
            files.append({
                'name': file_name,
                'type': file_type,
                'uploaded_at': str(datetime.now())
            })
            redis_client.set('workspace:files', json.dumps(files))
        
        # Broadcast to all terminals
        socketio.emit('workspace_updated', {
            'action': 'file_uploaded',
            'file_name': file_name,
            'file_type': file_type
        })
        
        return jsonify({
            'success': True,
            'message': f'File {file_name} uploaded to workspace',
            'file_name': file_name
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/workspace/files', methods=['GET'])
def list_workspace_files():
    """List all files in the collaborative workspace"""
    try:
        workspace_files = redis_client.get('workspace:files')
        if workspace_files:
            files = json.loads(workspace_files)
        else:
            files = []
        
        return jsonify({'files': files})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/workspace/file/<file_name>', methods=['GET'])
def get_workspace_file(file_name):
    """Get content of a specific file from workspace"""
    try:
        file_key = f"workspace:file:{file_name}"
        file_data = redis_client.get(file_key)
        
        if file_data:
            return jsonify(json.loads(file_data))
        else:
            return jsonify({'error': 'File not found'}), 404
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/workspace/task', methods=['POST'])
def create_collaborative_task():
    """Create a new collaborative task"""
    try:
        data = request.get_json()
        task_name = data.get('name', 'Untitled Task')
        task_description = data.get('description', '')
        assigned_terminals = data.get('terminals', [])
        
        task_id = f"task_{int(time.time())}"
        task_data = {
            'id': task_id,
            'name': task_name,
            'description': task_description,
            'assigned_terminals': assigned_terminals,
            'status': 'active',
            'created_at': str(datetime.now()),
            'progress': []
        }
        
        # Store task in Redis
        redis_client.set(f"workspace:task:{task_id}", json.dumps(task_data))
        
        # Add to task list
        tasks = redis_client.get('workspace:tasks')
        if tasks:
            task_list = json.loads(tasks)
        else:
            task_list = []
        
        task_list.append({
            'id': task_id,
            'name': task_name,
            'status': 'active',
            'assigned_terminals': assigned_terminals
        })
        redis_client.set('workspace:tasks', json.dumps(task_list))
        
        # Broadcast task creation
        socketio.emit('task_created', task_data)
        
        return jsonify({
            'success': True,
            'task_id': task_id,
            'task': task_data
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/workspace/tasks', methods=['GET'])
def list_tasks():
    """List all collaborative tasks"""
    try:
        tasks = redis_client.get('workspace:tasks')
        if tasks:
            return jsonify({'tasks': json.loads(tasks)})
        else:
            return jsonify({'tasks': []})
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/workspace/task/<task_id>/progress', methods=['POST'])
def update_task_progress(task_id):
    """Update progress on a collaborative task"""
    try:
        data = request.get_json()
        terminal_id = data.get('terminal')
        action = data.get('action')
        details = data.get('details', '')
        
        # Get current task
        task_key = f"workspace:task:{task_id}"
        task_data = redis_client.get(task_key)
        
        if task_data:
            task = json.loads(task_data)
            progress_entry = {
                'terminal': terminal_id,
                'action': action,
                'details': details,
                'timestamp': str(datetime.now())
            }
            
            task['progress'].append(progress_entry)
            redis_client.set(task_key, json.dumps(task))
            
            # Broadcast progress update
            socketio.emit('task_progress_updated', {
                'task_id': task_id,
                'progress': progress_entry
            })
            
            return jsonify({'success': True})
        else:
            return jsonify({'error': 'Task not found'}), 404
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@socketio.on('execute_command')
def handle_command(data):
    """Handle command execution from frontend"""
    command = data.get('command', '')
    terminal_type = data.get('terminal', 'system')
    
    if not command:
        emit('command_output', {'error': 'No command provided'})
        return
    
    try:
        if terminal_type == 'gemini-1':
            # Check if command looks like a system command (but allow gemini commands)
            system_commands = ['npm', 'npx', 'git', 'ls', 'pwd', 'cd', 'mkdir', 'rm', 'cp', 'mv']
            command_lower = command.lower()
            
            # Allow gemini commands even if they contain system command words
            if command_lower.startswith('gemini') or command_lower.startswith('--help') or command_lower.startswith('-h'):
                # This is a valid gemini command, proceed
                pass
            elif any(cmd in command_lower for cmd in system_commands):
                emit('command_output', {
                    'error': f'❌ This looks like a system command. Please use the System Terminal for commands like "{command.split()[0]}".\n💡 Gemini CLI terminal is for AI assistance only.',
                    'output': '',
                    'terminal': 'gemini-1'
                })
                return
            
            # Route to Gemini CLI Container 1
            response = requests.post(f"{GEMINI_CLI_URL_1}/execute", 
                                   json={'command': command}, timeout=60)
            result = response.json()
            emit('command_output', {
                'output': result.get('output', ''),
                'error': result.get('error', ''),
                'terminal': 'gemini-1'
            })
            
        elif terminal_type == 'gemini-2':
            # Check if command looks like a system command (but allow gemini commands)
            system_commands = ['npm', 'npx', 'git', 'ls', 'pwd', 'cd', 'mkdir', 'rm', 'cp', 'mv']
            command_lower = command.lower()
            
            # Allow gemini commands even if they contain system command words
            if command_lower.startswith('gemini') or command_lower.startswith('--prompt') or command_lower.startswith('-p'):
                # This is a valid gemini command, proceed
                pass
            elif any(cmd in command_lower for cmd in system_commands):
                emit('command_output', {
                    'error': f'❌ This looks like a system command. Please use the System Terminal for commands like "{command.split()[0]}".\n💡 Gemini CLI terminal is for AI chat assistance only.',
                    'output': '',
                    'terminal': 'gemini-2'
                })
                return
            
            # Route to Gemini CLI Container 2
            response = requests.post(f"{GEMINI_CLI_URL_2}/execute", 
                                   json={'command': command}, timeout=60)
            result = response.json()
            emit('command_output', {
                'output': result.get('output', ''),
                'error': result.get('error', ''),
                'terminal': 'gemini-2'
            })
            
        elif terminal_type == 'gemini-3':
            # Check if command looks like a system command (but allow gemini commands)
            system_commands = ['npm', 'npx', 'git', 'ls', 'pwd', 'cd', 'mkdir', 'rm', 'cp', 'mv']
            command_lower = command.lower()
            
            # Allow gemini commands even if they contain system command words
            if command_lower.startswith('gemini') or command_lower.startswith('--prompt') or command_lower.startswith('-p'):
                # This is a valid gemini command, proceed
                pass
            elif any(cmd in command_lower for cmd in system_commands):
                emit('command_output', {
                    'error': f'❌ This looks like a system command. Please use the System Terminal for commands like "{command.split()[0]}".\n💡 Gemini CLI terminal is for AI chat assistance only.',
                    'output': '',
                    'terminal': 'gemini-3'
                })
                return
            
            # Route to Gemini CLI Container 3
            response = requests.post(f"{GEMINI_CLI_URL_3}/execute", 
                                   json={'command': command}, timeout=60)
            result = response.json()
            emit('command_output', {
                'output': result.get('output', ''),
                'error': result.get('error', ''),
                'terminal': 'gemini-3'
            })
            
        else:
            # System command - execute locally
            import subprocess
            import shlex
            
            try:
                # Handle multiple commands on one line
                if ';' in command or '&&' in command or '||' in command:
                    # Use shell=True for command chaining
                    result = subprocess.run(
                        command,
                        shell=True,
                        capture_output=True,
                        text=True,
                        timeout=30
                    )
                else:
                    # Use subprocess to execute system commands
                    result = subprocess.run(
                        shlex.split(command),
                        capture_output=True,
                        text=True,
                        timeout=30
                    )
                
                output = result.stdout if result.stdout else ''
                error = result.stderr if result.stderr else ''
                
                emit('command_output', {
                    'output': output,
                    'error': error,
                    'terminal': 'system'
                })
                
            except subprocess.TimeoutExpired:
                emit('command_output', {
                    'error': 'Command timed out after 30 seconds',
                    'output': '',
                    'terminal': 'system'
                })
            except FileNotFoundError:
                emit('command_output', {
                    'error': f'Command not found: {command.split()[0]}',
                    'output': '',
                    'terminal': 'system'
                })
            except Exception as e:
                emit('command_output', {
                    'error': f'System command error: {str(e)}',
                    'output': '',
                    'terminal': 'system'
                })
            
    except requests.exceptions.Timeout as e:
        emit('command_output', {
            'error': f'Command timed out. The AI agent may be processing a complex request. Please try again.',
            'output': '',
            'terminal': terminal_type
        })
    except requests.exceptions.ConnectionError as e:
        emit('command_output', {
            'error': f'Cannot connect to {terminal_type} container. Please check if the container is running.',
            'output': '',
            'terminal': terminal_type
        })
    except requests.exceptions.RequestException as e:
        emit('command_output', {
            'error': f'Container communication error: {str(e)}',
            'output': '',
            'terminal': terminal_type
        })

if __name__ == '__main__':
    try:
        socketio.run(app, host='0.0.0.0', port=5001, debug=False, allow_unsafe_werkzeug=True)
    except Exception as e:
        print(f"Error starting server: {e}")
        # Fallback to regular Flask
        app.run(host='0.0.0.0', port=5001, debug=False) 