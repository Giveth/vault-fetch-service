#!/bin/bash

set -e

# Get Current User
CURRENT_USER="$(whoami)"
# Get current directory
SCRIPT_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Load environment variables from .env file
source "$SCRIPT_DIR/.env"
# Define service scripts
scripts=('vault-fetcher')
# Get environment variable file name
ENV_FILE="$SCRIPT_DIR/.env"

# Check if the script is running as root
function check_root {
  if [ "$EUID" -ne 0 ]; then
      echo "Please run the script as root or with sudo."
      exit 1
  fi
}

function check_connectivity {
  echo "Checking connectivity and validating the Vault token..."
  STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/auth/token/lookup-self")

  if [[ $STATUS_CODE -eq 200 ]]; then
      echo "Connected successfully to Vault and the token is valid."
      return 0
  else
      echo "Error: Could not connect to Vault at $VAULT_ADDR or the token is invalid."
      return 1
  fi
}

# Install the service using the defined scripts
function install_services {

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
}

# Run functions
function main {
    check_root
    if check_connectivity; then
        install_services
    else
        echo "Connectivity to Vault is not OK. Aborting Installation."
    fi
}

main
