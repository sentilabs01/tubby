#!/usr/bin/env python3
"""
Restart backend with correct environment variables
"""

import os
import subprocess
import time
import signal
import psutil

def find_backend_process():
    """Find the backend process"""
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            if proc.info['cmdline'] and any('app.py' in cmd for cmd in proc.info['cmdline']):
                return proc
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    return None

def restart_backend():
    """Restart the backend"""
    print("🔄 Restarting Backend...")
    
    # Set environment variables
    os.environ['FRONTEND_URL'] = 'http://localhost:3003'
    
    # Find and kill existing backend process
    backend_proc = find_backend_process()
    if backend_proc:
        print(f"   Stopping existing backend (PID: {backend_proc.pid})")
        backend_proc.terminate()
        try:
            backend_proc.wait(timeout=5)
        except psutil.TimeoutExpired:
            backend_proc.kill()
    
    # Start new backend process
    print("   Starting new backend process...")
    try:
        subprocess.Popen([
            'python', 'backend/app.py'
        ], env=os.environ, cwd='.')
        
        # Wait a moment for the server to start
        time.sleep(3)
        
        print("   ✅ Backend restarted successfully")
        print("   🌐 Backend should be running on http://localhost:5001")
        
    except Exception as e:
        print(f"   ❌ Failed to restart backend: {e}")

if __name__ == "__main__":
    restart_backend() 