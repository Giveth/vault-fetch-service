# Hashicorp Vault Fetcher
A simple systemd service that fetches Hashicorp Vault Secrets based on your configurations and needs.
## Getting Started
Clone the repo on your own server:
```
git clone https://github.com/Giveth/vault-fetch-service.git && cd vault-fetch-service
```
## Configuration
1. Make a config copy:
    ```
    cp .env.template .env
    ```
2. Paste in your own Vault Configurations:
    ```
    ## Authentication
    VAULT_ADDR='https://vault.mydomain.com'
    ENGINE_NAME='example-kv'
    VAULT_TOKEN=''
    
    ## The path for the secret store paths on vault
    VAULT_SECRET_PATH='my-app/secrets/config'
    
    ## The path for configuration files on Server
    ENV_TARGET='path/of/the/env/file/on/server/myapps.env'
    ```
## Installation & Uninstallation
1. Install the service
    ```
    sudo bash install-svc.sh
    ```
2. Uninstall the service
    ```
    sudo bash uninstall-svc.sh
    ```

