#!/usr/bin/env zsh

echo "Copying deploy.map and token..."

read "REMOTE_HOST?SSH destination in <user>@<ipaddr> form: "

read "DEPLOY_FILE?Name of local deploy.map file to copy to remote host: "

# Replace leading ~ with $HOME
DEPLOY_FILE="${DEPLOY_FILE/#\~/$HOME}"

if [ ! -f "$DEPLOY_FILE" ]; then
    echo "ERROR: Deploy map file $DEPLOY_FILE does not exist"
    exit 1
fi

## Create a dummy known_hosts file
SOCKET="/tmp/ssh_mux_%h_%p_%r"


echo "Enter vault names one by one.  Press ENTER on an empty line when finished:"

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

echo "Setting up SSH ControlMaster connection to $REMOTE_HOST"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -f -N -M -S $SOCKET $REMOTE_HOST 

## Copy over the deployment map file
echo "Copying file to $REMOTE_HOST:~/.deploy/deploy.map"
scp -o ControlPath="$SOCKET" "$DEPLOY_FILE" $REMOTE_HOST:~/.deploy/deploy.map

echo "Generating token for vaults: ${VAULTS[*]}..."
echo "And transferring token to $REMOTE_HOST:~/.deploy/token"
ssh -S "$SOCKET" $REMOTE_HOST "cat > ~/.deploy/token" < <(op service-account create "$SA_NAME" "${VAULTS[@]}" --expires-in=4m --raw)

echo "Completed transfer - closing ControlMaster connection"
ssh -S "$SOCKET" -O exit $REMOTE_HOST
