#!/usr/bin/env zsh

# Remove true when ready to execute
DRY_RUN=true

run() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN]: $@"
    else
        eval "$@"
    fi
}

### Use the following command to insert the token and generate a new script
# ./mkGetSecrets.sh
OP_SERVICE_ACCOUNT_TOKEN="$OPSTOKEN"
export OP_SERVICE_ACCOUNT_TOKEN


# OP URI format:
# op://[Vault name]/[Item name]/[[Section name (optional]]/[Field name]
## Example of getting a SSH private key
VAULT="Nix Bootstrap"
ITEM="NIXID SSH Key"
FIELD="private key?ssh-format=openssh"
OUTFILE="~/.ssh/nixid_ed25519"
PUBFILE="${OUTFILE}.pub"
run "op read \"op://$VAULT/$ITEM/$FIELD\" --out-file $OUTFILE"
# Generate the SSH public key from its private key
run "ssh-keygen -y -f ${OUTFILE} > ${PUBFILE}"
chmod 644 "${PUBFILE}"

## Example of getting an AGE key
VAULT="Nix Bootstrap"
ITEM="NIXID age private key"
FIELD="notesPlain"
OUTFILE="~/.age/nixid_key.txt"
PUBFILE="${OUTFILE/key/public}"
run "op read \"op://$VAULT/$ITEM/$FIELD\" --out-file $OUTFILE"
# Generate the AGE public key from its private key
run "age-keygen -y -o ${PUBFILE} ${OUTFILE}"
chmod 644 "${PUBFILE}"

