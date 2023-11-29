#!/bin/bash

set -e

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script as root or with sudo."
    exit 1
fi

# List of services based on your initial script
services=('vault-fetcher')

for service in "${services[@]}"; do
  # Check if service is active and stop it
  if systemctl is-active --quiet "$service"; then
    echo "Stopping service $service..."
    systemctl stop "$service"
  fi
  
  # Disable the service
  echo "Disabling service $service..."
  systemctl disable "$service"
  
  # Remove the service file
  echo "Removing service file for $service..."
  rm -f "/etc/systemd/system/$service.service"
  
  echo "Service $service uninstalled."
done

# Reload the systemd daemon to recognize changes
systemctl daemon-reload
echo "All services uninstalled and systemd daemon reloaded."
