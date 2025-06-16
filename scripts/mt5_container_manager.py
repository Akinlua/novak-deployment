#!/usr/bin/env python3
"""
MT5 Container Manager Script

This script manages the MT5 container lifecycle:
- Automatic restart every 12 hours
- Health monitoring and automatic recovery
- Container restart on demand
- Works both from host system and inside Docker containers
"""

import subprocess
import time
import logging
import os
import sys
import argparse
import requests
import socket
from datetime import datetime, timedelta
from typing import Optional

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/mt5_container_manager.log'),
        logging.StreamHandler()
    ]
)

def is_running_in_docker():
    """Check if the script is running inside a Docker container"""
    try:
        # Check for .dockerenv file
        if os.path.exists('/.dockerenv'):
            return True
        
        # Check cgroup for docker
        with open('/proc/1/cgroup', 'r') as f:
            content = f.read()
            if 'docker' in content or 'containerd' in content:
                return True
                
        return False
    except:
        return False

class MT5ContainerManager:
    def __init__(self):
        """Initialize the MT5 container manager"""
        self.container_name = os.environ.get('MT5_CONTAINER_NAME', 'mt5_user')
        self.mt5_image = os.environ.get('MT5_IMAGE', 'gmag11/metatrader5_vnc')
        self.mt5_port = os.environ.get('MT5_PORT', '8001')
        self.mt5_host = os.environ.get('MT5_HOST', 'localhost')
        self.restart_interval = 12 * 3600  # 12 hours in seconds
        self.health_check_interval = 5 * 60  # 5 minutes in seconds
        self.last_restart = datetime.now()
        self.running_in_docker = is_running_in_docker()
        
        if self.running_in_docker:
            logging.info("Detected running inside Docker container")
            # When running inside Docker, we need to access the host's Docker daemon
            self.docker_command_prefix = "docker"
        else:
            logging.info("Running on host system")
            self.docker_command_prefix = "docker"
        
    def run_command(self, command, capture_output=True):
        """Run a shell command and return the result"""
        try:
            if capture_output:
                result = subprocess.run(
                    command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                return result.returncode == 0, result.stdout, result.stderr
            else:
                result = subprocess.run(command, shell=True, timeout=30)
                return result.returncode == 0, "", ""
        except subprocess.TimeoutExpired:
            logging.error(f"Command timed out: {command}")
            return False, "", "Command timed out"
        except Exception as e:
            logging.error(f"Error running command '{command}': {str(e)}")
            return False, "", str(e)

    def is_container_running(self):
        """Check if MT5 container is running"""
        success, stdout, _ = self.run_command(f"{self.docker_command_prefix} ps --filter name={self.container_name} --format '{{{{.Names}}}}'")
        return success and self.container_name in stdout

    def stop_container(self):
        """Stop MT5 container"""
        logging.info(f"Stopping container {self.container_name}")
        success, stdout, stderr = self.run_command(f"{self.docker_command_prefix} stop {self.container_name}")
        if success:
            logging.info(f"Container {self.container_name} stopped successfully")
        else:
            logging.error(f"Failed to stop container: {stderr}")

    def remove_container(self):
        """Remove MT5 container"""
        logging.info(f"Removing container {self.container_name}")
        success, stdout, stderr = self.run_command(f"{self.docker_command_prefix} rm {self.container_name}")
        if success:
            logging.info(f"Container {self.container_name} removed successfully")
        else:
            logging.warning(f"Failed to remove container (may not exist): {stderr}")

    def start_container(self):
        """Start MT5 container"""
        logging.info(f"Starting container {self.container_name}")
        cmd = f"{self.docker_command_prefix} run -d --name {self.container_name} \
                 -p {self.mt5_port}:{self.mt5_port} \
                 --restart unless-stopped \
                 {self.mt5_image}"
        
        success, stdout, stderr = self.run_command(cmd)
        if success:
            logging.info(f"Container {self.container_name} started successfully")
            return True
        else:
            logging.error(f"Failed to start container: {stderr}")
            return False

    def restart_container(self):
        """Restart the MT5 container"""
        try:
            logging.info("Restarting MT5 container...")
            
            # Stop and remove existing container
            self.stop_container()
            
            # Start new container
            self.start_container()
            
            # Wait for container to be ready
            time.sleep(30)
            
            # Notify trading engine about restart
            self.notify_restart()
            
            logging.info("MT5 container restarted successfully")
            
        except Exception as e:
            logging.error(f"Error restarting MT5 container: {str(e)}")

    def restart_container_direct(self):
        """Restart the MT5 container using direct docker command"""
        try:
            logging.info("Restarting MT5 container using direct docker command...")
            success, stdout, stderr = self.run_command(f"{self.docker_command_prefix} restart {self.container_name}")
            if success: 
                logging.info("MT5 container restarted using direct docker command")
                self.notify_restart()
                return True
            else:
                logging.error(f"Failed to restart container: {stderr}")
                return False
        except Exception as e:
            logging.error(f"Error restarting MT5 container: {str(e)}")  
            
    def notify_restart(self):
        """Notify the trading engine about MT5 restart"""
        try:
            # Get trading engine URL from environment or default to localhost
            trading_engine_url = os.environ.get('TRADING_ENGINE_URL', 'http://localhost:5001')
            
            notification_data = {
                'timestamp': datetime.now().isoformat(),
                'message': 'MT5 container restarted'
            }
            
            # Send notification to trading engine
            response = requests.post(
                f'{trading_engine_url}/api/mt5-restart-notification',
                json=notification_data,
                timeout=10
            )
            
            if response.status_code == 200:
                logging.info("Successfully notified trading engine about MT5 restart")
            else:
                logging.warning(f"Failed to notify trading engine: {response.status_code}")
                
        except Exception as e:
            logging.warning(f"Could not notify trading engine about restart: {str(e)}")

    def wait_for_container_ready(self, max_wait_seconds=60):
        """Wait for MT5 container to be ready"""
        logging.info("Waiting for MT5 container to be ready...")
        start_time = time.time()
        
        while (time.time() - start_time) < max_wait_seconds:
            if self.health_check():
                logging.info("MT5 container is ready")
                return True
            time.sleep(5)
        
        logging.error("MT5 container failed to become ready within timeout")
        return False

    def notify_trading_engine_restart(self):
        """Notify trading engine about MT5 restart"""
        try:
            # Call trading engine endpoint to reinitialize connections
            trading_engine_url = os.environ.get('TRADING_ENGINE_URL', 'http://localhost:5001')
            response = requests.post(
                f"{trading_engine_url}/api/mt5-restart-notification",
                json={'timestamp': datetime.now().isoformat()},
                timeout=10
            )
            
            if response.status_code == 200:
                logging.info("Trading engine notified of MT5 restart")
            else:
                logging.warning(f"Failed to notify trading engine: {response.status_code}")
                
        except Exception as e:
            logging.error(f"Error notifying trading engine: {str(e)}")

    def health_check(self):
        """Run health check on MT5 container"""
        if not self.is_container_running():
            logging.warning("MT5 container is not running")
            return False
        
        try:
            # Check if port is accessible
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((self.mt5_host, int(self.mt5_port)))
            sock.close()
            
            if result == 0:
                logging.debug("MT5 health check passed")
                return True
            else:
                logging.warning("MT5 port is not accessible")
                return False
                
        except Exception as e:
            logging.error(f"Health check error: {str(e)}")
            return False

    def monitor_loop(self):
        """Main monitoring loop"""
        while True:
            try:
                current_time = datetime.now()
                
                # Check for scheduled restart (every 12 hours)
                if (current_time - self.last_restart).total_seconds() >= self.restart_interval:
                    logging.info("Scheduled restart time reached")
                    self.restart_container_direct()
                    self.last_restart = current_time
                
                # Perform health check
                elif not self.health_check():
                    logging.warning("Health check failed, restarting container")
                    self.restart_container_direct()
                    self.last_restart = current_time
                
                # Wait before next check
                time.sleep(self.health_check_interval)
                
            except KeyboardInterrupt:
                logging.info("Monitoring stopped by user")
                break
            except Exception as e:
                logging.error(f"Error in monitoring loop: {str(e)}")
                time.sleep(60)  # Wait a minute before retrying

    def restart_now(self):
        """Force restart container now"""
        logging.info("Force restart requested")
        self.restart_container_direct()
        return True

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='MT5 Container Manager')
    parser.add_argument('--restart-now', action='store_true', help='Restart container immediately and exit')
    parser.add_argument('--daemon', action='store_true', help='Run as daemon with scheduled restarts')
    parser.add_argument('--health-check', action='store_true', help='Run single health check and exit')
    
    args = parser.parse_args()
    
    manager = MT5ContainerManager()
    
    if args.restart_now:
        success = manager.restart_now()
        sys.exit(0 if success else 1)
    elif args.health_check:
        healthy = manager.health_check()
        print(f"Health check: {'PASSED' if healthy else 'FAILED'}")
        sys.exit(0 if healthy else 1)
    elif args.daemon:
        manager.monitor_loop()
    else:
        print("Use --daemon to run as service, --restart-now for immediate restart, or --health-check for health check")

if __name__ == "__main__":
    main() 