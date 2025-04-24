# Custom MT5 Container with Exness

## Setup Instructions

1. Download the Exness MT5 installer and place it in this directory as `mt5-exness-setup.exe`
2. Build and run the container using docker-compose:
   ```
   cd ../
   docker-compose build mt5
   docker-compose up -d
   ```

3. Access the VNC interface at http://localhost:3001 to verify the setup

## What This Does

This custom container:
1. Uses the base MT5-VNC image
2. Installs the Exness MT5 client
3. Configures it to run with RPyC enabled for programmatic access

The MT5 terminal data will be persisted in the Docker volume.

## Note

This MT5 container in the trading-engine is configured to use different ports:
- VNC: 3001 (central server uses 3000)
- RPyC: 8002 (central server uses 8001) 