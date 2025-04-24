#!/bin/bash

# Novak Trading Engine Easy Installation Script
# This script helps users quickly set up and deploy the trading engine

set -e  # Exit on error

echo "====================================================="
echo "   Novak Trading Engine - Easy Installation Script   "
echo "====================================================="

# Check if script is running in interactive mode
INTERACTIVE=true
if [ ! -t 0 ]; then
    INTERACTIVE=false
    echo "Running in non-interactive mode"
fi

# Create installation directory
INSTALL_DIR="$HOME/novak-trading-engine"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "Installing to: $INSTALL_DIR"
echo "====================================================="

# Check if Docker is installed, if not install it
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    
    # Add current user to docker group to avoid using sudo with docker
    sudo usermod -aG docker $USER
    echo "Docker has been installed. You might need to log out and log back in for group changes to take effect."
fi

# Check if Docker Compose is installed, if not install it
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    sudo apt install -y docker-compose
    echo "Docker Compose has been installed."
fi

# Create directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR/logs"
mkdir -p "$INSTALL_DIR/data"
mkdir -p "$INSTALL_DIR/mt5_data"
mkdir -p "$INSTALL_DIR/mt5-custom"

# Download the latest docker-compose.yml and MT5 custom files
echo "Downloading latest configuration files..."
curl -s https://raw.githubusercontent.com/Akinlua/novak-deployment/refs/heads/main/docker-compose.yml > docker-compose.yml
curl -s https://raw.githubusercontent.com/Akinlua/novak-deployment/refs/heads/main/mt5-custom/Dockerfile > mt5-custom/Dockerfile
curl -s https://raw.githubusercontent.com/Akinlua/novak-deployment/refs/heads/main/mt5-custom/README.md > mt5-custom/README.md
curl -s https://raw.githubusercontent.com/Akinlua/novak-deployment/refs/heads/main/mt5-custom/mt5-exness-setup.exe > mt5-custom/mt5-exness-setup.exe

# Remove existing .env file if it exists
if [ -f ".env" ]; then
    echo "Removing existing .env file..."
    rm -f .env
fi

# Create .env file with default values
echo "Creating .env file..."
cat > .env << EOL
# Novak Trading Engine Environment Variables
# Please edit these values with your own configuration

# Server settings
FLASK_DEBUG=True
SECRET_KEY=SYRYUR

MONGO_USERNAME=admin
MONGO_PASSWORD=secretpassword

# # MongoDB connection
# MONGODB_URI=mongodb://\${MONGO_USERNAME}:\${MONGO_PASSWORD}@mongodb:27017/novak_trading?authSource=admin

# MT5 default settings (can be overridden at runtime)
MT5_SERVER=Exness-MT5Trial
MT5_LOGIN=your_mt5_login
MT5_PASSWORD=your_mt5_password
MT5_HOST=147.93.112.143
MT5_PORT=8002

MT5_VNC_USER=admin
MT5_VNC_PASSWORD=admin

# Logging
LOG_LEVEL=INFO

# Central Server Configuration
CENTRAL_SERVER_URL=http://147.93.112.143:5002

# License
LICENSE_KEY=your_license_key_here 
EOL
echo "Please edit the .env file with your MT5 credentials and license key."
echo "The file is located at: $INSTALL_DIR/.env"

# Ask user if they want to edit the .env file now (only in interactive mode)
if [ "$INTERACTIVE" = true ]; then
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
else
    echo "====================================================="
    echo "Running in non-interactive mode - skipping .env editing"
    echo "Please edit the .env file manually at: $INSTALL_DIR/.env before starting services"
fi

# Start the containers
echo "====================================================="
echo "Starting Novak Trading Engine..."
# Stop any existing containers to prevent conflicts
docker-compose down || true

# Configure firewall to allow access to the application
echo "Configuring firewall rules..."
if command -v ufw &> /dev/null; then
    sudo ufw status | grep -q "Status: active" && {
        echo "Opening ports 5001, 8001, 8002 for Trading Engine API..."
        sudo ufw allow 5001/tcp
        sudo ufw allow 5002/tcp
        sudo ufw allow 8001/tcp
        sudo ufw allow 8002/tcp
        
        echo "Firewall configured successfully."
    } || {
        echo "UFW is installed but not active. No firewall changes made."
    }
else
    echo "UFW not found. Skipping firewall configuration."
fi

echo "Building custom MT5 container..."
# docker-compose build mt5
docker-compose pull

echo "Starting all services..."
docker-compose up -d

# Show status and connection information
echo "====================================================="
echo "Novak Trading Engine has been started!"
echo "Trading Engine API: http://localhost:5001"
echo "MT5 VNC Access: http://localhost:3001 (user: admin, password: from .env)"
echo "MongoDB Admin Interface: http://localhost:8081 (login with MongoDB credentials)"
echo "====================================================="
echo "To monitor the logs, run: docker-compose logs -f"
echo "To stop the engine, run: docker-compose down"
echo "====================================================="
echo "Thank you for using Novak Trading Engine!" 