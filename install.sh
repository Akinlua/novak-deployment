#!/bin/bash

# Novak Trading Engine Easy Installation Script
# This script helps users quickly set up and deploy the trading engine

set -e  # Exit on error

# Parse command line arguments
LICENSE_KEY=""
MT5_LOGIN=""
MT5_PASSWORD=""
MT5_SERVER="Exness-MT5Trial9"
SECRET_KEY="SYRYUR"
MT5_HOST="localhost"
MT5_PORT="8002"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --license-key KEY       Set the license key"
    echo "  --mt5-login LOGIN       Set MT5 login"
    echo "  --mt5-password PASS     Set MT5 password"
    echo "  --mt5-server SERVER     Set MT5 server (default: Exness-MT5Trial)"
    echo "  --secret-key KEY        Set Flask secret key (default: SYRYUR)" 
    echo "  --mt5-host HOST         Set MT5 host (default: localhost)"
    echo "  --mt5-port PORT         Set MT5 port (default: 8002)"
    echo "  --help                  Show this help message"
    echo ""
    echo "Example:"
    echo "  curl -sSL https://raw.githubusercontent.com/Akinlua/novak-deployment/refs/heads/main/install.sh | bash -s -- --license-key YOUR_LICENSE --mt5-login 12345 --mt5-password yourpass"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --license-key)
            LICENSE_KEY="$2"
            shift 2
            ;;
        --mt5-login)
            MT5_LOGIN="$2"
            shift 2
            ;;
        --mt5-password)
            MT5_PASSWORD="$2"
            shift 2
            ;;
        --mt5-server)
            MT5_SERVER="$2"
            shift 2
            ;;
        --secret-key)
            SECRET_KEY="$2"
            shift 2
            ;;
        --mt5-host)
            MT5_HOST="$2"
            shift 2
            ;;
        --mt5-port)
            MT5_PORT="$2"
            shift 2
            ;;
        --help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

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

# Create defaults directory and menu.xml
echo "Creating defaults directory and menu.xml..."
mkdir -p "$INSTALL_DIR/defaults"
cat > "$INSTALL_DIR/defaults/menu.xml" << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
<menu id="root-menu" label="MENU">
<item label="xterm" icon="/usr/share/pixmaps/xterm-color_48x48.xpm"><action name="Execute"><command>/usr/bin/xterm</command></action></item>
<item label="Metatrader 5 Exness" icon="/config/.wine/drive_c/Program Files/MetaTrader 5 EXNESS/Terminal.ico"><action name="Execute"><command>/usr/bin/wine "/config/.wine/drive_c/Program Files/MetaTrader 5 Exness/terminal64.exe"</command></action></item>
</menu>
</openbox_menu>
EOL

# Save the custom start.sh for MT5
echo "Creating custom start.sh for MT5..."
cat > "$INSTALL_DIR/custom_start.sh" << 'EOL'
#!/bin/bash

# Configuration variables
mt5file='/config/.wine/drive_c/Program Files/MetaTrader 5 EXNESS/terminal64.exe'
WINEPREFIX='/config/.wine'
wine_executable="wine"
metatrader_version="5.0.36"
mt5server_port="8001"
mono_url="https://dl.winehq.org/wine/wine-mono/8.0.0/wine-mono-8.0.0-x86.msi"
python_url="https://www.python.org/ftp/python/3.9.0/python-3.9.0.exe"
mt5setup_url="https://download.mql5.com/cdn/web/exness.technologies.ltd/mt5/exness5setup.exe"

# Function to display a graphical message
show_message() {
    echo $1
}

# Function to check if a dependency is installed
check_dependency() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 is not installed. Please install it to continue."
        exit 1
    fi
}

# Function to check if a Python package is installed
is_python_package_installed() {
    python3 -c "import pkg_resources; exit(not pkg_resources.require('$1'))" 2>/dev/null
    return $?
}

# Function to check if a Python package is installed in Wine
is_wine_python_package_installed() {
    $wine_executable python -c "import pkg_resources; exit(not pkg_resources.require('$1'))" 2>/dev/null
    return $?
}

# Check for necessary dependencies
check_dependency "curl"
check_dependency "$wine_executable"

# Install Mono if not present
if [ ! -e "/config/.wine/drive_c/windows/mono" ]; then
    show_message "[1/7] Downloading and installing Mono..."
    curl -o /config/.wine/drive_c/mono.msi $mono_url
    WINEDLLOVERRIDES=mscoree=d $wine_executable msiexec /i /config/.wine/drive_c/mono.msi /qn
    rm /config/.wine/drive_c/mono.msi
    show_message "[1/7] Mono installed."
else
    show_message "[1/7] Mono is already installed."
fi

# Check if MetaTrader 5 is already installed
if [ -e "$mt5file" ]; then
    show_message "[2/7] File $mt5file already exists."
else
    show_message "[2/7] File $mt5file is not installed. Installing..."

    # Set Windows 10 mode in Wine and download and install MT5
    $wine_executable reg add "HKEY_CURRENT_USER\\Software\\Wine" /v Version /t REG_SZ /d "win10" /f
    show_message "[3/7] Downloading EXNESS MT5 installer..."
    curl -o /config/.wine/drive_c/exness5setup.exe $mt5setup_url
    show_message "[3/7] Installing EXNESS MT5..."
    $wine_executable "/config/.wine/drive_c/exness5setup.exe" "/auto" &
    wait
    rm -f /config/.wine/drive_c/exness5setup.exe
fi

# Recheck if MetaTrader 5 is installed
if [ -e "$mt5file" ]; then
    show_message "[4/7] File $mt5file is installed. Running MT5..."
    $wine_executable "$mt5file" &
else
    show_message "[4/7] File $mt5file is not installed. MT5 cannot be run."
fi


# Install Python in Wine if not present
if ! $wine_executable python --version 2>/dev/null; then
    show_message "[5/7] Installing Python in Wine..."
    curl -L $python_url -o /tmp/python-installer.exe
    $wine_executable /tmp/python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
    rm /tmp/python-installer.exe
    show_message "[5/7] Python installed in Wine."
else
    show_message "[5/7] Python is already installed in Wine."
fi

# Upgrade pip and install required packages
show_message "[6/7] Installing Python libraries"
$wine_executable python -m pip install --upgrade --no-cache-dir pip
# Install MetaTrader5 library in Windows if not installed
show_message "[6/7] Installing MetaTrader5 library in Windows"
if ! is_wine_python_package_installed "MetaTrader5==$metatrader_version"; then
    $wine_executable python -m pip install --no-cache-dir MetaTrader5==$metatrader_version
fi
# Install mt5linux library in Windows if not installed
show_message "[6/7] Checking and installing mt5linux library in Windows if necessary"
if ! is_wine_python_package_installed "mt5linux"; then
    $wine_executable python -m pip install --no-cache-dir mt5linux
fi

# Install mt5linux library in Linux if not installed
show_message "[6/7] Checking and installing mt5linux library in Linux if necessary"
if ! is_python_package_installed "mt5linux"; then
    pip install --upgrade --no-cache-dir mt5linux
fi

# Install pyxdg library in Linux if not installed
show_message "[6/7] Checking and installing pyxdg library in Linux if necessary"
if ! is_python_package_installed "pyxdg"; then
    pip install --upgrade --no-cache-dir pyxdg
fi

# Start the MT5 server on Linux
show_message "[7/7] Starting the mt5linux server..."
python3 -m mt5linux --host 0.0.0.0 -p $mt5server_port -w $wine_executable python.exe &

# Give the server some time to start
sleep 5

# Check if the server is running
if ss -tuln | grep ":$mt5server_port" > /dev/null; then
    show_message "[7/7] The mt5linux server is running on port $mt5server_port."
else
    show_message "[7/7] Failed to start the mt5linux server on port $mt5server_port."
fi
EOL

# Remove existing .env file if it exists
if [ -f ".env" ]; then
    echo "Removing existing .env file..."
    rm -f .env
fi

# Create .env file with default values
echo "Creating .env file..."

# Set default values if not provided via command line
if [ -z "$LICENSE_KEY" ]; then
    LICENSE_KEY="your_license_key_here"
fi

if [ -z "$MT5_LOGIN" ]; then
    MT5_LOGIN="your_mt5_login"
fi

if [ -z "$MT5_PASSWORD" ]; then
    MT5_PASSWORD="your_mt5_password"
fi

if [ -z "$MT5_HOST" ]; then
    MT5_HOST="localhost"
fi

if [ -z "$MT5_PORT" ]; then
    MT5_PORT="8002"
fi
cat > .env << EOL
# Novak Trading Engine Environment Variables
# Please edit these values with your own configuration
PORT = 5001

# Server settings
FLASK_DEBUG=True
SECRET_KEY=$SECRET_KEY

MONGO_USERNAME=admin
MONGO_PASSWORD=secretpassword

# # MongoDB connection
# MONGODB_URI=mongodb://\${MONGO_USERNAME}:\${MONGO_PASSWORD}@mongodb:27017/novak_trading?authSource=admin

# MT5 default settings (can be overridden at runtime)
MT5_SERVER=$MT5_SERVER
MT5_LOGIN=$MT5_LOGIN
MT5_PASSWORD=$MT5_PASSWORD
MT5_HOST=$MT5_HOST
MT5_PORT=$MT5_PORT

MT5_VNC_USER=admin
MT5_VNC_PASSWORD=admin

# Logging
LOG_LEVEL=INFO

# Central Server Configuration
CENTRAL_SERVER_URL=http://147.93.112.143:5002

# License
LICENSE_KEY=$LICENSE_KEY 
EOL

# Show what was configured
echo "Configuration applied:"
if [ "$LICENSE_KEY" != "your_license_key_here" ]; then
    echo "  ✓ License key: Set"
else
    echo "  ⚠ License key: Using default (please update manually)"
fi

if [ "$MT5_LOGIN" != "your_mt5_login" ]; then
    echo "  ✓ MT5 Login: $MT5_LOGIN"
else
    echo "  ⚠ MT5 Login: Using default (please update manually)"
fi

if [ "$MT5_PASSWORD" != "your_mt5_password" ]; then
    echo "  ✓ MT5 Password: Set"
else
    echo "  ⚠ MT5 Password: Using default (please update manually)"
fi

echo "  ✓ MT5 Server: $MT5_SERVER"
echo "Please edit the .env file with your MT5 credentials and license key if not provided via command line."
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
        sudo apt install ufw
        sudo ufw allow 5001/tcp
        sudo ufw allow 5002/tcp
        sudo ufw allow 8001/tcp
        sudo ufw allow 8002/tcp
        sudo ufw allow 8003/tcp
        
        echo "Firewall configured successfully."
    } || {
        echo "UFW is installed but not active. No firewall changes made."
    }
else
    echo "UFW not found. Skipping firewall configuration."
fi

echo "Pulling images..."
docker-compose pull

echo "Starting all services..."
docker-compose up -d

# Wait for the MT5 container to be ready
echo "Waiting for MT5 container to start..."
sleep 10

# Get the MT5 container ID
MT5_CONTAINER_ID=$(docker ps | grep mt5_user | awk '{print $1}')

if [ -z "$MT5_CONTAINER_ID" ]; then
    echo "Error: MT5 container not found!"
    exit 1
fi

echo "====================================================="
echo "Customizing MT5 container..."

# Install necessary packages in the container
echo "Installing necessary packages in the MT5 container..."
docker exec $MT5_CONTAINER_ID apt-get update
docker exec $MT5_CONTAINER_ID apt-get install -y nano

# Replace the start.sh in the MT5 container
echo "Replacing start.sh in the MT5 container..."
docker cp "$INSTALL_DIR/custom_start.sh" $MT5_CONTAINER_ID:/Metatrader/start.sh
docker exec $MT5_CONTAINER_ID chmod +x /Metatrader/start.sh

# Replace the menu.xml in the MT5 container
echo "Replacing menu.xml in the MT5 container..."
docker cp "$INSTALL_DIR/defaults/menu.xml" $MT5_CONTAINER_ID:/defaults/menu.xml

docker exec $MT5_CONTAINER_ID chmod +x /defaults/menu.xml

# Restart the MT5 container
echo "Restarting MT5 container to apply changes..."
docker restart $MT5_CONTAINER_ID

# Wait for the MT5 container to restart
echo "Waiting for MT5 container to restart..."
sleep 15

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