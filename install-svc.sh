#!/bin/bash

set -e

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script as root or with sudo."
    exit 1
fi

# Get Current User
CURRENT_USER="$(whoami)"

# Get current directory
SCRIPT_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Define scripts
scripts=('vault-fetcher')

# Get environment variables from .env file
ENV_VARS=$(sed -n -e '/^#/!p' "$SCRIPT_DIR/.env" | grep -v -e '^$')
ENV_FILE="$SCRIPT_DIR/.env"

for script in "${scripts[@]}"; do
  # Create systemd service file
  cat > "$script.service" <<EOF
[Unit]
Description=Vault Secret Fetcher for $script
After=network.target
[Service]
WorkingDirectory=$SCRIPT_DIR
Type=simple
User=$CURRENT_USER
Group=users
TimeoutStartSec=0
Restart=on-failure
RestartSec=10s
ExecStart=/bin/bash $SCRIPT_DIR/$script.sh
EnvironmentFile=$ENV_FILE
[Install]
WantedBy=multi-user.target
EOF

  # Move the service file to the correct directory
  sudo mv "$script.service" /etc/systemd/system/

  # Reload systemd, enable and start the service
  sudo systemctl daemon-reload
  sudo systemctl enable $script
  sudo systemctl start $script

  echo "The service $script has been installed and started. You can check its status with 'systemctl status $script'"
done
