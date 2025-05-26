# Novak Trading Engine

## Easy Installation

### Quick Start (Basic Installation)
You can install and run the Novak Trading Engine with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/Akinlua/novak-deployment/refs/heads/main/install.sh | bash
```

### Quick Start with Your Credentials
For a complete setup with your credentials in one command:

```bash
curl -sSL https://raw.githubusercontent.com/Akinlua/novak-deployment/refs/heads/main/install.sh | bash -s -- --license-key YOUR_LICENSE_KEY --mt5-login YOUR_MT5_LOGIN --mt5-password YOUR_MT5_PASSWORD
```

### Available Options
You can customize the installation with these options:

```bash
curl -sSL https://raw.githubusercontent.com/Akinlua/novak-deployment/refs/heads/main/install.sh | bash -s -- [OPTIONS]
```

**Options:**
- `--license-key KEY`: Set your license key
- `--mt5-login LOGIN`: Set your MT5 login number
- `--mt5-password PASS`: Set your MT5 password
- `--mt5-server SERVER`: Set MT5 server (default: Exness-MT5Trial)
- `--secret-key KEY`: Set Flask secret key (default: SYRYUR)
- `--mt5-host`: set the ip address of your server here
- `--mt5-port`: the port of mt5 (default to 8002)
- `--help`: Show help message

**Example with all options:**
```bash
curl -sSL https://raw.githubusercontent.com/Akinlua/novak-deployment/refs/heads/main/install.sh | bash -s -- \
  --license-key "abc123xyz" \
  --mt5-login "12345678" \
  --mt5-password "mypassword" \
  --mt5-server "Exness-MT5Trial" \
  --secret-key "mysecretkey" \
  --mt5-host "localhost" \
  --mt5-port "8002"
```

This command will:
1. Create an installation directory in your home folder
2. Download the required configuration files
3. Set up the Docker environment with your credentials
4. Start the trading engine

## Manual Installation

If you prefer to review the installation script before running it, you can:

1. Download the installation script:
```bash
curl -O https://raw.githubusercontent.com/Akinlua/novak-deployment/refs/heads/main/install.sh
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
