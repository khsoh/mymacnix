#!/usr/bin/env zsh

set -u
set -o pipefail

nixtmpDir="$(mktemp -d -t scpdeploydir.XXXXXXXXX || \
          echo "Can't create temporary directory for deploying secrets remotely")"

cleanup() {
    rm -rf "$nixtmpDir"
}

trap cleanup EXIT INT TERM QUIT

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
KNOWN_HOSTS="$nixtmpDir/known_hosts"
touch $KNOWN_HOSTS

## Copy over the file
echo "Copying file to remote host"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=$KNOWN_HOSTS "$DEPLOY_FILE" $REMOTE_HOST:~/.deploy/deploy.map


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

echo "Generating token for vaults: ${VAULTS[*]}..."

# Generate the unique name
SA_NAME="tmp-$(date +%Y%m%d-%H%M)-$(uuidgen | head -c 8)"

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=$KNOWN_HOSTS $REMOTE_HOST "cat > ~/.deploy/token" < <(op service-account create "$SA_NAME" "${VAULTS[@]}" --expires-in=2m --raw)
