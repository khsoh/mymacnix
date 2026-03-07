#!/usr/bin/env zsh

set -e          # Exit n Error
set -u          # Error on undefined variables
set -o pipefail # Capture exit codes in pipes

## Create a SSH ControlMaster socket
SOCKET=""
REMOTE_HOST=""

function cleanup() {
    # 1. Only try to close SSH if both SOCKET and REMOTE_HOST are set
    if [[ -n "$SOCKET" && -n "$REMOTE_HOST" ]]; then
        # Check if the socket file actually exists before talking to it
        if [[ -S "$SOCKET" ]]; then
            ssh -S "$SOCKET" -O exit "$REMOTE_HOST" 2>/dev/null
        fi
    fi

    # 2. Final file cleanup (always safe to -f)
    [[ -n "$SOCKET" ]] && rm -f "$SOCKET"
}

# Zsh handles traps slightly differently; EXIT is usually sufficient
# but listing the signals ensures cleanup on Ctrl+C (INT) or kill (TERM)
trap cleanup EXIT INT TERM QUIT


echo "Copying deploy.map and token..."

vared -p "SSH destination in <user>@<ipaddr> form: " -c REMOTE_HOST

vared -p "Name of local deploy.map file to copy to remote host: " -c DEPLOY_FILE

# Replace leading ~ with $HOME
DEPLOY_FILE="${DEPLOY_FILE/#\~/$HOME}"

if [ ! -f "$DEPLOY_FILE" ]; then
    echo "ERROR: Deploy map file $DEPLOY_FILE does not exist"
    exit 1
fi


echo "Enter vault names one line at a time and press ENTER for each vault."
echo "Press ENTER on an empty line when finished:"

VAULTS=()
while true; do
    # Use vared for a nice prompt; -p is the prompt string
    vared -p "Add Vault: " -c TMP_VAULT
    
    # If the user enters nothing, break the loop
    [[ -z "$TMP_VAULT" ]] && break
    
    # Add the vault name to our array and clear the temp variable
    VAULTS+=("--vault" "$TMP_VAULT")
    unset TMP_VAULT
done

# Check if any vaults were added
if [[ ${#VAULTS[@]} -eq 0 ]]; then
    echo "No vaults specified. Exiting."
    exit 1
fi

# Generate the unique name
SA_NAME="tmp-$(date +%Y%m%d-%H%M)-$(uuidgen | head -c 8)"

SOCKET="$HOME/ssh_mux_$$.sock"
echo "Setting up SSH ControlMaster connection to $REMOTE_HOST in background"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -fNM -S "$SOCKET" "$REMOTE_HOST"

## Copy over the deployment map file
echo "Copying file to \"$REMOTE_HOST:~/.deploy/deploy.map\""
scp -o ControlPath="$SOCKET" "$DEPLOY_FILE" "$REMOTE_HOST:~/.deploy/deploy.map"

echo "Generating token for vaults:..."
printf "%s \"%s\"\n" "${VAULTS[@]}"
echo "And transferring token to \"$REMOTE_HOST:~/.deploy/token\""
ssh -S "$SOCKET" "$REMOTE_HOST" "cat > ~/.deploy/token" < <(op service-account create "$SA_NAME" "${VAULTS[@]}" --expires-in=4m --raw)

echo "Completed transfer - closing SSH ControlMaster connection"
ssh -S "$SOCKET" -O exit "$REMOTE_HOST"
