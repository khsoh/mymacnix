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
    print_green "  $1 [<user> <host>]"
    print_green " <user> : Username - should be one folder names under ../dot-config/nixpkgs/secrets/user"
    print_green " <host> : Host - should be one folder names under ../dot-config/nixpkgs/secrets/host"
    print_green " If no arguments are provided, scripts are generated at ~/.deploy to deploy the secrets at the local host and user"
    exit 1
}

INSTALL_REMOTE=1
if [ "$#" -eq 2 ]; then
    XUSER=$1
    XHOST=$2
elif [ "$#" -eq 0 ]; then
    INSTALL_REMOTE=""
    XHOST="$(/usr/sbin/scutil --get LocalHostName)"
    XUSER=$(nix-instantiate --eval --json --strict -E '(import (<darwin-config> + "/../secrets/getpkinfo.nix")).pkuser.name')
    XUSER="${XUSER%\"}" # Remove trailing quote
    XUSER="${XUSER#\"}" # Remove leading quote
else
    usage $0
fi

## Validate the user and host name
DARWINDIR=$(nix-instantiate --eval -E '<darwin-config>')
USERDIR=$(readlink -f "${DARWINDIR}/../secrets/user")
HOSTDIR=$(readlink -f "${DARWINDIR}/../secrets/host")
goodargs=1
if [[ ! -d "$USERDIR/$XUSER" ]]; then
    print_red "ERROR: $XUSER does not exist in $USERDIR"
    print_red "Available users:"
    print_green "$(ls $USERDIR)"
    goodargs=""
fi

if [[ ! -d "$HOSTDIR/$XHOST" ]]; then
    print_red "ERROR: $XHOST does not exist in $HOSTDIR"
    print_red "Available hosts:"
    print_green "$(ls $HOSTDIR)"
    goodargs=""
fi

[ -n "$goodargs" ] || exit 1

print_green "Deploying from user: ${USERDIR}/$XUSER"
print_green "Deploying from host: ${HOSTDIR}/$XHOST"

PKDATA=$(nix-instantiate --eval --strict --json - <<EOF
let
  base = <darwin-config>;
  pkdata = import (base + "/../secrets/getpkinfo.nix");
in
{
  pkuser = pkdata.users."$XUSER";
  pkhost = pkdata.hosts."$XHOST";
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
)
HOSTCMDS=$(cat <<EOFX
#!/usr/bin/env zsh
readonly ESC="\$(tput sgr0)"
readonly BOLD="\$(tput bold)"
readonly GREEN="\$(tput setaf 2)"
readonly RED="\$(tput setaf 1)"
pushd ~/.deploy
sudo -E -s <<'EOF'
EOFX
)

function run() {
    if [ -n "$INSTALL_REMOTE" ]; then
        ssh -S "$SOCKET" "$REMOTE_HOST" "zsh -c '$1'"
    else
        zsh -c "$1"
    fi
}

if [ -n "$INSTALL_REMOTE" ]; then
    ## Install remotely
    vared -p "SSH destination in <user>@<ipaddr> form: " -c REMOTE_HOST

    SOCKET="$HOME/ssh_mux_$$.sock"
    print_green "Setting up SSH ControlMaster connection to $REMOTE_HOST in background"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -fNM -S "$SOCKET" "$REMOTE_HOST"
fi

## Create a clean deployment directory in host
print_green "Creating clean deployment directory in ~/.deploy at $XHOST"
run "rm -rf ~/.deploy && mkdir -p ~/.deploy/root"


## Copy the user secrets
echo $PKDATA | jq '.pkuser.DEPLOY' | jq -c '.[]' | while read -r item; do
  opuri=$(echo "$item" | jq -r ".OPURI")
  file=$(echo "$item" | jq -r ".FILE")
  cmds=$(echo "$item" | jq -r ".POSTCMD" | jq -r '.[]')

  # Get the secret into the remote host destination
  op read "$opuri" | run "mkdir -p \$(dirname $file) && umask 077 && cat > $file"
  USERCMDS=$(cat <<EOF
$USERCMDS
$cmds
printf "\${GREEN}\${BOLD}Installed $file\${ESC}\\n"
EOF
)
done
USERCMDS="$USERCMDS\npopd\n"
echo "$USERCMDS" | run "cat > ~/.deploy/userdeploy.sh && chmod +x ~/.deploy/userdeploy.sh"

## Copy the host secrets
echo $PKDATA | jq '.pkhost.DEPLOY' | jq -c '.[]' | while read -r item; do
  opuri=$(echo "$item" | jq -r ".OPURI")
  file=$(echo "$item" | jq -r ".FILE")
  cmds=$(echo "$item" | jq -r ".POSTCMD" | jq -r '.[]')

  # Get the secret into the remote host destination
  op read "$opuri" | run "mkdir -p \$(dirname ~/.deploy/root/$file) && umask 077 && cat > ~/.deploy/root/$file"
  HOSTCMDS=$(cat <<EOF
$HOSTCMDS
mkdir -p \$(dirname $file)
$cmds
printf "\${GREEN}\${BOLD}Installed $file\${ESC}\\n"
EOF
)
done
HOSTCMDS="$HOSTCMDS\nEOF\npopd\n"
echo "$HOSTCMDS" | run "cat > ~/.deploy/hostdeploy.sh && chmod +x ~/.deploy/hostdeploy.sh && touch ~/.deploy/completed"

if [ -n "$INSTALL_REMOTE" ]; then
    print_green "Completed transfer - closing SSH ControlMaster connection"
    ssh -S "$SOCKET" -O exit "$REMOTE_HOST"
fi
