from flask import Blueprint, jsonify, request
import docker
import subprocess

terminal_bp = Blueprint('terminal', __name__)

# Docker client for container management
docker_client = docker.from_env()

@terminal_bp.route('/containers/status', methods=['GET'])
def get_container_status():
    """Get the status of AI agent containers"""
    try:
        containers = {}
        
        # Check Claude Code container
        try:
            claude_container = docker_client.containers.get('claude-code-instance')
            containers['claude'] = {
                'status': claude_container.status,
                'name': claude_container.name,
                'id': claude_container.id[:12]
            }
        except docker.errors.NotFound:
            containers['claude'] = {
                'status': 'not_found',
                'name': 'claude-code-instance',
                'id': None
            }
        
        # Check Gemini CLI container
        try:
            gemini_container = docker_client.containers.get('gemini-cli-instance')
            containers['gemini'] = {
                'status': gemini_container.status,
                'name': gemini_container.name,
                'id': gemini_container.id[:12]
            }
        except docker.errors.NotFound:
            containers['gemini'] = {
                'status': 'not_found',
                'name': 'gemini-cli-instance',
                'id': None
            }
        
        return jsonify({
            'success': True,
            'containers': containers
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@terminal_bp.route('/execute', methods=['POST'])
def execute_command():
    """Execute a command in the appropriate container or local shell"""
    data = request.get_json()
    command = data.get('command', '')
    terminal_id = data.get('terminal_id', 'terminal1')
    
    if not command:
        return jsonify({
            'success': False,
            'error': 'No command provided'
        }), 400
    
    try:
        if command.startswith('claude'):
            # Route to Claude Code container
            container = docker_client.containers.get('claude-code-instance')
            result = container.exec_run(command, stdout=True, stderr=True)
            output = result.output.decode('utf-8')
            return jsonify({
                'success': True,
                'terminal_id': terminal_id,
                'command': command,
                'output': output,
                'type': 'claude'
            })
        elif command.startswith('gemini'):
            # Route to Gemini CLI container
            container = docker_client.containers.get('gemini-cli-instance')
            result = container.exec_run(command, stdout=True, stderr=True)
            output = result.output.decode('utf-8')
            return jsonify({
                'success': True,
                'terminal_id': terminal_id,
                'command': command,
                'output': output,
                'type': 'gemini'
            })
        else:
            # Execute in local shell
            result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
            output = result.stdout + result.stderr
            return jsonify({
                'success': True,
                'terminal_id': terminal_id,
                'command': command,
                'output': output,
                'type': 'shell'
            })
    except subprocess.TimeoutExpired:
        return jsonify({
            'success': False,
            'error': 'Command timed out after 30 seconds'
        }), 408
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

