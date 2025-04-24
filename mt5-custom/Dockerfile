# Base image: MT5 with VNC and RPyC
FROM gmag11/metatrader5_vnc:latest

# Set working directory
WORKDIR /app

# Copy your Exness MT5 installer into the image
# You'll need to place your mt5-exness-setup.exe in this directory
COPY mt5-exness-setup.exe /app/mt5-exness-setup.exe

# Install needed dependencies (if not already present)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wine64 \
        xvfb \
    && rm -rf /var/lib/apt/lists/*

# Run Exness setup under Wine with silent install
RUN xvfb-run --auto-servernum wine start /unix \
        /app/mt5-exness-setup.exe /SILENT

# Change CMD to launch the Exness terminal with RPyC enabled
CMD ["xvfb-run", "--auto-servernum", "wine", "~/.wine/drive_c/Program Files/Exness MetaTrader 5/terminal64.exe", \
     "/portable", \
     "/rpyc:8002"] 