# Novak Trading Engine

## Easy Installation

You can install and run the Novak Trading Engine with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/Akinlua/Novak/backend/trading-engine/install.sh | bash
```

This command will:
1. Create an installation directory in your home folder
2. Download the required configuration files
3. Set up the Docker environment
4. Start the trading engine

## Manual Installation

If you prefer to review the installation script before running it, you can:

1. Download the installation script:
```bash
curl -O https://raw.githubusercontent.com/Akinlua/Novak/backend/trading-engine/install.sh
```

2. Review the script:
```bash
cat install.sh
```

3. Make it executable and run it:
```bash
chmod +x install.sh
./install.sh
```

## Configuration

After installation, you'll need to edit the `.env` file in the installation directory with your:
- MT5 credentials
- License key
- Other optional settings

## Usage

- To check status: `docker-compose ps`
- To view logs: `docker-compose logs -f`
- To stop: `docker-compose down`
- To restart: `docker-compose up -d`

## MT5 VNC Access

You can access the MetaTrader 5 interface through your web browser at:
- URL: http://localhost:3001
- Username: admin
- Password: (defined in your .env file)

## API Access

The Trading Engine API is available at: http://localhost:5001
