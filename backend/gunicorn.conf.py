# Gunicorn configuration for Tubby AI Backend
import os
import multiprocessing

# Server socket
bind = f"0.0.0.0:{os.getenv('PORT', '5004')}"
backlog = 2048

# Worker processes
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "eventlet"
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 50
timeout = 30
keepalive = 2

# Restart workers after this many requests, to help prevent memory leaks
preload_app = True

# Logging
accesslog = "-"
errorlog = "-"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "tubby-backend"

# Server mechanics
daemon = False
pidfile = "/tmp/tubby-backend.pid"
user = None
group = None
tmp_upload_dir = None

# SSL (if needed)
# keyfile = None
# certfile = None

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# Debugging
reload = False
reload_engine = "auto"
spew = False

# Server hooks
def on_starting(server):
    server.log.info("Starting Tubby AI Backend")

def on_reload(server):
    server.log.info("Reloading Tubby AI Backend")

def worker_int(worker):
    worker.log.info("worker received INT or QUIT signal")

def pre_fork(server, worker):
    server.log.info("Worker spawned (pid: %s)", worker.pid)

def post_fork(server, worker):
    server.log.info("Worker spawned (pid: %s)", worker.pid)

def post_worker_init(worker):
    worker.log.info("Worker initialized (pid: %s)", worker.pid)

def worker_abort(worker):
    worker.log.info("Worker aborted (pid: %s)", worker.pid)

def pre_exec(server):
    server.log.info("Forked child, re-executing.")

def when_ready(server):
    server.log.info("Server is ready. Spawning workers")

def worker_exit(server, worker):
    server.log.info("Worker exited (pid: %s)", worker.pid)

def nworkers_changed(server, new_value, old_value):
    server.log.info("Number of workers changed from %s to %s", old_value, new_value)

def on_exit(server):
    server.log.info("Server exiting") 