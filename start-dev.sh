#!/bin/bash

# Novak Trading Engine Development Startup Script
# This script starts the trading engine with Flask's development server

set -e

# Set development values
export FLASK_ENV=development
export FLASK_DEBUG=True
export PORT=${PORT:-8000}

# Change to app directory
cd "$(dirname "$0")"

# Create logs directory if it doesn't exist
mkdir -p logs

# Print startup information
echo "=============================================="
echo "Starting Novak Trading Engine (Development)"
echo "=============================================="
echo "Environment: $FLASK_ENV"
echo "Debug Mode: $FLASK_DEBUG"
echo "Port: $PORT"
echo "=============================================="

# Start Flask development server
export FLASK_APP=src/app.py
python -m flask run --host=0.0.0.0 --port=$PORT 