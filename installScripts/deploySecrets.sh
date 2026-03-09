#!/usr/bin/env zsh

set -e          # Exit n Error
set -u          # Error on undefined variables
set -o pipefail # Capture exit codes in pipes

readonly ESC="$(tput sgr0)"
readonly BOLD="$(tput bold)"
readonly GREEN="$(tput setaf 2)"
readonly RED="$(tput setaf 1)"

SCRIPTNAME=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPTNAME")

function print_green () {
    printf "${BOLD}${GREEN}"
    printf "$*${ESC}\n"
}

function print_red () {
    printf "${BOLD}${RED}"
    printf "$*${ESC}\n"
}

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

    printf "${ESC}"
}

# Zsh handles traps slightly differently; EXIT is usually sufficient
# but listing the signals ensures cleanup on Ctrl+C (INT) or kill (TERM)
trap cleanup EXIT INT TERM QUIT


function usage () {
    print_green "Usage: "
    print_green "  $1 <user> <host>"
    print_green " <user> : Username - should be one folder names under ../dot-config/nixpkgs/secrets/user"
    print_green " <host> : Host - should be one folder names under ../dot-config/nixpkgs/secrets/host"
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage $0
fi

## Validate the user and host name
DARWINDIR=$(nix-instantiate --eval -E '<darwin-config>')
USERDIR=$(readlink -f "${DARWINDIR}/../secrets/user")
HOSTDIR=$(readlink -f "${DARWINDIR}/../secrets/host")
goodargs=true
if [[ ! -d "$USERDIR/$1" ]]; then
    print_red "ERROR: $1 does not exist in $USERDIR"
    print_red "Available users:"
    print_green "$(ls $USERDIR)"
    goodargs=false
fi

if [[ ! -d "$HOSTDIR/$2" ]]; then
    print_red "ERROR: $2 does not exist in $HOSTDIR"
    print_red "Available hosts:"
    print_green "$(ls $HOSTDIR)"
    goodargs=false
fi

$goodargs || exit 1

print_green "Deploying from user: ${USERDIR}/$1"
print_green "Deploying from host: ${HOSTDIR}/$1"

PKDATA=$(nix-instantiate --eval --strict --json - <<EOF
let
  base = <darwin-config>;
  pkdata = import (base + "/../secrets/getpkinfo.nix");
in
{
  pkuser = pkdata.users."$1";
  pkhost = pkdata.hosts."$2";
}
EOF
)

USERCMDS=$(cat <<EOF
#!/usr/bin/env zsh
readonly ESC="\$(tput sgr0)"
readonly BOLD="\$(tput bold)"
readonly GREEN="\$(tput setaf 2)"
readonly RED="\$(tput setaf 1)"
pushd ~/.deploy
EOF
HOSTCMDS=$(cat <<EOFX
#!/usr/bin/env zsh
readonly ESC="\$(tput sgr0)"
readonly BOLD="\$(tput bold)"
readonly GREEN="\$(tput setaf 2)"
readonly RED="\$(tput setaf 1)"
pushd ~/.deploy
sudo -E -s <<'EOF'
EOFX

vared -p "SSH destination in <user>@<ipaddr> form: " -c REMOTE_HOST

SOCKET="$HOME/ssh_mux_$$.sock"
print_green "Setting up SSH ControlMaster connection to $REMOTE_HOST in background"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -fNM -S "$SOCKET" "$REMOTE_HOST"

## Create a clean deployment directory in host
print_green "Creating clean deployment directory in ~/.deploy at $REMOTE_HOST"
ssh -S "$SOCKET" "$REMOTE_HOST" "rm -rf ~/.deploy && mkdir -p ~/.deploy/root"

## Copy over the user files
echo $PKDATA | jq '.pkuser.DEPLOY' | jq -c '.[]' | while read -r item; do
  opuri=$(echo "$item" | jq -r ".OPURI")
  file=$(echo "$item" | jq -r ".FILE")
  cmds=$(echo "$item" | jq -r ".POSTCMD" | jq -r '.[]')

  # Get the secret into the remote host destination
  op read "$opuri" | ssh -S "$SOCKET" "$REMOTE_HOST" "mkdir -p \$(dirname $file) && umask 077 && cat > $file"
  USERCMDS="$USERCMDS$cmds\n\${GREEN}\${BOLD}Installed $file\${ESC}\n"
done
USERCMDS="$USERCMDS\npopd\n"
echo "$USERCMDS" | ssh -S "$SOCKET" "$REMOTE_HOST" "cat > ~/.deploy/userdeploy.sh && chmod +x ~/.deploy/userdeploy.sh"

## Copy over the root files
echo $PKDATA | jq '.pkhost.DEPLOY' | jq -c '.[]' | while read -r item; do
  opuri=$(echo "$item" | jq -r ".OPURI")
  file=$(echo "$item" | jq -r ".FILE")
  cmds=$(echo "$item" | jq -r ".POSTCMD" | jq -r '.[]')

  # Get the secret into the remote host destination
  op read "$opuri" | ssh -S "$SOCKET" "$REMOTE_HOST" "mkdir -p \$(dirname ~/.deploy/root/$file) && umask 077 && cat > ~/.deploy/root/$file"
  HOSTCMDS="$HOSTCMDS$cmds\${GREEN}\${BOLD}Installed $file\${ESC}\n"
done
HOSTCMDS="$HOSTCMDS\nEOF\npopd\n"
echo "$HOSTCMDS" | ssh -S "$SOCKET" "$REMOTE_HOST" "cat > ~/.deploy/hostdeploy.sh && chmod +x ~/.deploy/hostdeploy.sh && touch ~/.deploy/completed"

print_green "Completed transfer - closing SSH ControlMaster connection"
ssh -S "$SOCKET" -O exit "$REMOTE_HOST"
