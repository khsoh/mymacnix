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


function run() {
    if [ -n "$INSTALL_REMOTE" ]; then
        ssh -S "$SOCKET" "$REMOTE_HOST" "zsh -c '$1'"
    else
        zsh -c "$1"
    fi
}

function usage () {
    print_green "Usage: "
    print_green "  $1 (<user>@<host> | localhost)"
    print_green " <user>@<host> : the ssh host to connect to"
    print_green " localhost : deploy locally. Scripts are generated at ~/.deploy to deploy the secrets at the local host and user"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage $0
fi

INSTALL_REMOTE=1
if [[ "$1" == "localhost" ]]; then
    ## This is for deploying locally.
    INSTALL_REMOTE=""
else
    ## Install remotely
    REMOTE_HOST="$1"
    SOCKET="$HOME/ssh_mux_$$.sock"

    print_green "Setting up SSH ControlMaster connection to $REMOTE_HOST in background"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -fNM -S "$SOCKET" "$REMOTE_HOST"
fi

XHOST=$(run "/usr/sbin/scutil --get LocalHostName")
XUSER=$(run "/usr/bin/id -un")

#PKDATA=$(nix-instantiate --eval --strict --json -E "(import (<darwin-secrets> + \"/standalone.nix\") { host=\"$XHOST\"; user=\"$XUSER\"; }).target")
PKDATA=$(nix-instantiate --eval --strict --json -E "(import (<darwin-secrets> + \"/deploy.nix\") { host=\"$XHOST\"; user=\"$XUSER\"; })")

USERCMDS=$(cat <<EOF
#!/usr/bin/env zsh
readonly ESC="\$(tput sgr0)"
readonly BOLD="\$(tput bold)"
readonly GREEN="\$(tput setaf 2)"
readonly RED="\$(tput setaf 1)"
pushd ~/.deploy
printf "\${GREEN}\${BOLD}"
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
printf "\${GREEN}\${BOLD}"
EOFX
)

## Create a clean deployment directory in host
print_green "Creating clean deployment directory in ~/.deploy at $XHOST"
run "rm -rf ~/.deploy && mkdir -p ~/.deploy/root"


## Copy the user secrets
XUSER=$(echo $PKDATA | jq '.user.name')
print_green "Deploying secrets from <darwin-secrets>/user/${XUSER}"
echo $PKDATA | jq '.user.deployment' | jq -c '.[]' | while read -r item; do
  opuri=$(echo "$item" | jq -r ".OPURI")
  file=$(echo "$item" | jq -r ".FILE")
  cmds=$(echo "$item" | jq -r ".POSTCMD" | jq -r '.[]')

  # Get the secret into the remote host destination
  op read "$opuri" | run "mkdir -p \$(dirname $file) && umask 077 && cat > $file"
  USERCMDS=$(cat <<EOF
$USERCMDS
$cmds
echo "Installed $file"
EOF
)
done
USERCMDS="$USERCMDS\npopd\nprintf \"\${ESC}\""
echo "$USERCMDS" | run "cat > ~/.deploy/userdeploy.sh && chmod +x ~/.deploy/userdeploy.sh"

## Copy the host secrets
XHOST=$(echo $PKDATA | jq '.host.name')
print_green "Deploying secrets from <darwin-secrets>/host/${XHOST}"
echo $PKDATA | jq '.host.deployment' | jq -c '.[]' | while read -r item; do
  opuri=$(echo "$item" | jq -r ".OPURI")
  file=$(echo "$item" | jq -r ".FILE")
  cmds=$(echo "$item" | jq -r ".POSTCMD" | jq -r '.[]')

  # Get the secret into the remote host destination
  op read "$opuri" | run "mkdir -p \$(dirname ~/.deploy/root/$file) && umask 077 && cat > ~/.deploy/root/$file"
  HOSTCMDS=$(cat <<EOF
$HOSTCMDS
mkdir -p \$(dirname $file)
$cmds
echo "Installed $file"
EOF
)
done
HOSTCMDS="$HOSTCMDS\nEOF\npopd\nprintf \"\${ESC}\""
echo "$HOSTCMDS" | run "cat > ~/.deploy/hostdeploy.sh && chmod +x ~/.deploy/hostdeploy.sh && touch ~/.deploy/completed"

if [ -n "$INSTALL_REMOTE" ]; then
    print_green "Completed transfer - closing SSH ControlMaster connection"
    ssh -S "$SOCKET" -O exit "$REMOTE_HOST"
fi
