#!/bin/bash

# Novak Trading Engine Production Startup Script
# This script starts the trading engine with Gunicorn in production mode

set -e

# Set default values
export FLASK_ENV=${FLASK_ENV:-production}
export FLASK_DEBUG=${FLASK_DEBUG:-False}
export GUNICORN_WORKERS=${GUNICORN_WORKERS:-4}
export LOG_LEVEL=${LOG_LEVEL:-info}
export PORT=${PORT:-8000}

# Change to app directory
cd /app

# Create logs directory if it doesn't exist
mkdir -p logs

# Print startup information
echo "=============================================="
echo "Starting Novak Trading Engine with Gunicorn"
echo "=============================================="
echo "Environment: $FLASK_ENV"
echo "Debug Mode: $FLASK_DEBUG"
echo "Workers: $GUNICORN_WORKERS"
echo "Port: $PORT"
echo "Log Level: $LOG_LEVEL"
echo "=============================================="

# Start Gunicorn with configuration file
exec gunicorn \
    --config gunicorn.conf.py \
    --bind 0.0.0.0:$PORT \
    --workers $GUNICORN_WORKERS \
    --timeout 120 \
    --log-level $LOG_LEVEL \
    --access-logfile logs/gunicorn_access.log \
    --error-logfile logs/gunicorn_error.log \
    --capture-output \
    --preload \
    wsgi:app 