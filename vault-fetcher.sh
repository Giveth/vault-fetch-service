#!/bin/bash

# Get current directory
SCRIPT_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Load environment variables from .env file
source "$SCRIPT_DIR/.env"
# Output file
ENV_FILE="$ENV_TARGET"
# Secrets Path on Vault
SECRET_PATH="$VAULT_SECRET_PATH"
# Sleep interval in seconds
SLEEP_INTERVAL=10

function check_env_file {
  if [ ! -f "$ENV_FILE" ]; then
      echo "Error: $ENV_FILE not found!"
      echo "Creating the file now"
      touch "$ENV_FILE"
      echo "$ENV_FILE created."
  fi
}

function check_connectivity {
  echo "Checking connectivity and validating the Vault token..."
  STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/auth/token/lookup-self")

  if [[ $STATUS_CODE -eq 200 ]]; then
      echo "Connected successfully to Vault and the token is valid."
  else
      echo "Error: Could not connect to Vault at $VAULT_ADDR or the token is invalid."
      exit 1
  fi
}

function fetch_secrets {
  while true; do
    echo "Reading local secrets from $ENV_FILE..."
    LOCAL_SECRETS=$(cat $ENV_FILE)

    # Get Secrets
    echo "Fetching secrets from Vault..."
    SECRETS=$(curl -s \
      -H "X-Vault-Request: true" \
      -H "X-Vault-Token: $VAULT_TOKEN" \
      --request GET \
      "$VAULT_ADDR/v1/$ENGINE_NAME/data/$SECRET_PATH" | jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"')

    if [[ "$SECRETS" != "$LOCAL_SECRETS" ]]; then
      echo "Secrets have changed. Updating $ENV_FILE..."
      echo "$SECRETS" > $ENV_FILE
      echo "Update complete."
    else
      echo "No changes detected. $ENV_FILE remains the same."
    fi

    # Sleep for the specified interval before the next iteration
    sleep $SLEEP_INTERVAL
  done
}

# Run functions
function main {
    check_env_file
    if check_connectivity; then
        fetch_secrets
    else
        echo "Connectivity to Vault is not OK. Keeping the existing $ENV_FILE."
    fi
}

main
