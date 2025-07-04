# Gunicorn configuration file for Novak Trading Engine
import os
import multiprocessing

# Server socket
bind = f"0.0.0.0:{os.environ.get('PORT', '8000')}"

# Worker processes - Use single worker to avoid memory issues with trading bots
# Trading bots use background threads, so we don't need multiple workers
workers = 1  # Changed from multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000

# Remove max_requests to prevent worker restarts that lose trading bot instances
# max_requests = 1000
# max_requests_jitter = 100

# Timeout settings
timeout = 120  # Increased for long-running trading operations
keepalive = 5
graceful_timeout = 30

# Logging
loglevel = os.environ.get('LOG_LEVEL', 'info').lower()
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Log to both files and stdout/stderr for docker logs compatibility
accesslog = '/app/logs/gunicorn_access.log'
errorlog = '/app/logs/gunicorn_error.log'

# Also log to stdout/stderr for docker logs (set to '-' means stdout)
# You can comment out the lines below if you only want file logging
# accesslog = '-'  # This would log access to stdout
# errorlog = '-'   # This would log errors to stderr

capture_output = True

# Process naming
proc_name = 'novak-trading-engine'

# Server mechanics
daemon = False
pidfile = '/app/gunicorn.pid'
tmp_upload_dir = None

# SSL (if needed)
keyfile = os.environ.get('SSL_KEYFILE')
certfile = os.environ.get('SSL_CERTFILE')

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# Application
wsgi_module = "wsgi:app"
pythonpath = "/app"

# Preload application for better performance
preload_app = True

# Worker settings for trading operations
worker_tmp_dir = "/dev/shm"  # Use memory for temporary files

def on_starting(server):
    server.log.info("Starting Novak Trading Engine with Gunicorn")

def on_reload(server):
    server.log.info("Reloading Novak Trading Engine")

def worker_int(worker):
    worker.log.info("Worker received INT or QUIT signal")

def pre_fork(server, worker):
    server.log.info("Worker spawned (pid: %s)", worker.pid)

def post_fork(server, worker):
    server.log.info("Worker spawned (pid: %s)", worker.pid)

def when_ready(server):
    server.log.info("Novak Trading Engine ready to accept connections")

def worker_abort(worker):
    worker.log.info("Worker received SIGABRT signal") 