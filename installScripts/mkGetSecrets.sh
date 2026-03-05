#!/usr/bin/env zsh

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

export OPSTOKEN=$(op service-account create "$SA_NAME" "${VAULTS[@]}" --expires-in=10m --raw)
envsubst '$OPSTOKEN' < getSecrets-tmpl.sh > getSecrets.sh

echo "Success! Generated getSecrets.sh (valid for 10m)"
chmod +x getSecrets.sh

