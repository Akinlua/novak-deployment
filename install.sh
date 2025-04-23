#!/bin/bash

# Novak Trading Engine Easy Installation Script
# This script helps users quickly set up and deploy the trading engine

set -e  # Exit on error

echo "====================================================="
echo "   Novak Trading Engine - Easy Installation Script   "
echo "====================================================="

# Create installation directory
INSTALL_DIR="$HOME/novak-trading-engine"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "Installing to: $INSTALL_DIR"
echo "====================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker before continuing."
    echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose before continuing."
    echo "Visit https://docs.docker.com/compose/install/ for installation instructions."
    exit 1
fi

# Create directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR/logs"
mkdir -p "$INSTALL_DIR/data"

# Download the latest docker-compose.yml
echo "Downloading latest docker-compose.yml..."
curl -s https://raw.githubusercontent.com/Akinlua/Novak/backend/trading-engine/docker-compose.yml > docker-compose.yml

# Create .env file with default values if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating default .env file..."
    cat > .env << EOL
# Novak Trading Engine Environment Variables
# Please edit these values with your own configuration

# Required Settings
LICENSE_KEY=your_license_key_here
MT5_SERVER=your_mt5_server
MT5_LOGIN=your_mt5_login
MT5_PASSWORD=your_mt5_password

# Optional Settings (with defaults)
DOCKER_HUB_USERNAME=novaktrading
SECRET_KEY=change_this_to_a_secure_random_string
CENTRAL_SERVER_URL=https://api.novaktrading.com
MONGODB_URI=mongodb://mongodb:27017/novak_trading
MT5_VNC_PASSWORD=admin

# Advanced Settings (only change if you know what you're doing)
MT5_PORT=8001
EOL
    echo "Please edit the .env file with your MT5 credentials and license key."
    echo "The file is located at: $INSTALL_DIR/.env"
fi

# Ask user if they want to edit the .env file now
echo "====================================================="
echo "Would you like to edit the .env file now? (y/n)"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    if command -v nano &> /dev/null; then
        nano .env
    elif command -v vim &> /dev/null; then
        vim .env
    else
        echo "No editor found. Please edit the .env file manually at: $INSTALL_DIR/.env"
    fi
fi

# Start the containers
echo "====================================================="
echo "Starting Novak Trading Engine..."
docker-compose pull
docker-compose up -d

# Show status and connection information
echo "====================================================="
echo "Novak Trading Engine has been started!"
echo "Trading Engine API: http://localhost:5001"
echo "MT5 VNC Access: http://localhost:3001 (user: admin, password: from .env)"
echo "====================================================="
echo "To monitor the logs, run: docker-compose logs -f"
echo "To stop the engine, run: docker-compose down"
echo "====================================================="
echo "Thank you for using Novak Trading Engine!" 