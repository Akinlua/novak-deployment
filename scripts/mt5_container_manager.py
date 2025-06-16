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
        self.mt5_port = os.environ.get('MT5_PORT', '8002')
        self.mt5_host = os.environ.get('MT5_HOST', 'localhost')
        self.restart_interval = 12 * 3600  # 12 hours in seconds
        self.health_check_interval = 5 * 60  # 5 minutes in seconds
        self.last_restart = datetime.now()
        self.running_in_docker = is_running_in_docker()
        
        # Check if Docker socket is available
        self.docker_available = self._check_docker_availability()
        
        if self.running_in_docker:
            logging.info("Detected running inside Docker container")
            if self.docker_available:
                logging.info("Docker socket is available - container management enabled")
            else:
                logging.warning("Docker socket not available - container management disabled")
        else:
            logging.info("Running on host system")
        
        self.docker_command_prefix = "docker"
        
    def _check_docker_availability(self):
        """Check if Docker is available and accessible"""
        try:
            success, stdout, stderr = self.run_command("docker version --format '{{.Server.Version}}'")
            if success and stdout.strip():
                logging.info(f"Docker server available, version: {stdout.strip()}")
                return True
            else:
                logging.warning(f"Docker not available: {stderr}")
                return False
        except Exception as e:
            logging.warning(f"Error checking Docker availability: {str(e)}")
            return False
        
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
        """Check if the MT5 container is running"""
        if not self.docker_available:
            logging.warning("Docker not available - cannot check container status")
            return False
            
        try:
            success, stdout, stderr = self.run_command(
                f"{self.docker_command_prefix} ps --filter name={self.container_name} --format '{{{{.Names}}}}'"
            )
            
            if success:
                running_containers = stdout.strip().split('\n')
                is_running = self.container_name in running_containers
                logging.debug(f"Container {self.container_name} running: {is_running}")
                return is_running
            else:
                logging.error(f"Error checking container status: {stderr}")
                return False
                
        except Exception as e:
            logging.error(f"Error checking if container is running: {str(e)}")
            return False

    def start_container(self):
        """Start the MT5 container"""
        if not self.docker_available:
            logging.error("Docker not available - cannot start container")
            return False
            
        try:
            if self.is_container_running():
                logging.info("MT5 container is already running")
                return True
            
            logging.info("Starting MT5 container...")
            
            # First try to start existing container
            success, stdout, stderr = self.run_command(f"{self.docker_command_prefix} start {self.container_name}")
            
            if success:
                logging.info("MT5 container started successfully")
                return True
            else:
                logging.warning(f"Failed to start existing container: {stderr}")
                # Container might not exist, try to create and run it
                return self._create_and_run_container()
                
        except Exception as e:
            logging.error(f"Error starting MT5 container: {str(e)}")
            return False

    def _create_and_run_container(self):
        """Create and run a new MT5 container"""
        try:
            logging.info("Creating new MT5 container...")
            
            # Remove any existing stopped container with the same name
            self.run_command(f"{self.docker_command_prefix} rm -f {self.container_name}")
            
            # Run new container (this should match the docker-compose configuration)
            run_command = f"""
            {self.docker_command_prefix} run -d \
                --name {self.container_name} \
                -p 3001:3000 \
                -p 8002:8001 \
                -e CUSTOM_USER={os.environ.get('MT5_VNC_USER', 'admin')} \
                -e PASSWORD={os.environ.get('MT5_VNC_PASSWORD', 'admin')} \
                -v $(pwd)/mt5_data:/config \
                --restart unless-stopped \
                {self.mt5_image}
            """.strip().replace('\n', ' ').replace('\\', '')
            
            success, stdout, stderr = self.run_command(run_command)
            
            if success:
                logging.info("MT5 container created and started successfully")
                return True
            else:
                logging.error(f"Failed to create container: {stderr}")
                return False
                
        except Exception as e:
            logging.error(f"Error creating MT5 container: {str(e)}")
            return False

    def stop_container(self):
        """Stop the MT5 container"""
        if not self.docker_available:
            logging.error("Docker not available - cannot stop container")
            return False
            
        try:
            if not self.is_container_running():
                logging.info("MT5 container is not running")
                return True
            
            logging.info("Stopping MT5 container...")
            success, stdout, stderr = self.run_command(f"{self.docker_command_prefix} stop {self.container_name}")
            
            if success:
                logging.info("MT5 container stopped successfully")
                return True
            else:
                logging.error(f"Failed to stop container: {stderr}")
                return False
                
        except Exception as e:
            logging.error(f"Error stopping MT5 container: {str(e)}")
            return False

    def restart_container(self):
        """Restart the MT5 container"""
        if not self.docker_available:
            logging.error("Docker not available - cannot restart container")
            return False
            
        try:
            logging.info("Restarting MT5 container...")
            
            # Use docker restart command first (simpler and faster)
            success, stdout, stderr = self.run_command(f"{self.docker_command_prefix} restart {self.container_name}")
            
            if success:
                logging.info("MT5 container restarted successfully using docker restart")
                # Wait for container to be ready
                time.sleep(30)
                # Notify trading engine about restart
                self.notify_restart()
                self.last_restart = datetime.now()
                return True
            else:
                logging.warning(f"Docker restart failed: {stderr}. Trying manual stop/start...")
                # Fallback to manual stop/start
                return self._manual_restart()
            
        except Exception as e:
            logging.error(f"Error restarting MT5 container: {str(e)}")
            return False

    def _manual_restart(self):
        """Manual restart by stopping and starting container"""
        try:
            # Stop container
            if not self.stop_container():
                logging.error("Failed to stop container during manual restart")
                return False
            
            # Wait a moment
            time.sleep(5)
            
            # Start container
            if not self.start_container():
                logging.error("Failed to start container during manual restart")
                return False
            
            # Wait for container to be ready
            time.sleep(30)
            
            # Notify trading engine about restart
            self.notify_restart()
            self.last_restart = datetime.now()
            
            logging.info("MT5 container restarted successfully using manual restart")
            return True
            
        except Exception as e:
            logging.error(f"Error during manual restart: {str(e)}")
            return False

    def restart_container_direct(self):
        """Restart the MT5 container using direct docker command"""
        return self.restart_container()  # Use the improved restart method
            
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