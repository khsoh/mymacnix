#!/usr/bin/env bash

is_running_under_login() {
    local ppid=$$
    local parent_name=""

    # Loop until the parent is '/usr/bin/login' or we hit the root process (PID 0)
    while [[ "$ppid" -ne 0 ]]; do
        # Get the name of the parent process
        parent_name=$(ps -p "$ppid" -o comm= 2>/dev/null)

        if [[ "$parent_name" == "/usr/bin/login" ]]; then
            return 1 # Found '/usr/bin/login' in the hierarchy
        elif [[ -z "$parent_name" ]]; then
            # Process not found, assume we've hit an end state or an error
            break
        fi

        # Move up to the next parent
        ppid=$(ps -p "$ppid" -o ppid= 2>/dev/null)
    done

    return 2 # '/usr/bin/login' not found in the hierarchy
}

is_running_under_login
OUTPUT=$?

get_conditional_substring() {
    local value=$1
    local len=${2:-8}

    if [ "$OUTPUT" -eq 1 ]; then
        # Running in login - just use the whole length
        echo "$value"
    else
        echo "${value:0:$len}"
    fi
}

function cleanup() {
    printf "%s" "$ESC"
}

if [ "$OUTPUT" -eq 1 ]; then
    ESC="$(tput sgr0)"
    BOLD="$(tput bold)"
    GREEN="$(tput setaf 2)"
    RED="$(tput setaf 1)"
    BLUE="$(tput setaf 4)"
    readonly ESC
    readonly BOLD
    readonly GREEN
    readonly RED
    readonly BLUE

    trap cleanup EXIT INT TERM QUIT
    # Your login-shell-specific logic
    while getopts ":k" opt; do
        case ${opt} in
        k)
            # Kickstart the daemon
            launchctl kickstart gui/"$(id -u)"/org.nixos.hm.detectNixUpdates
            exit 0
            ;;
        \?)
            # Handle invalid option
            echo "Error: Invalid option: -${OPTARG}" >&2
            exit 1
            ;;
        esac
    done
else
    readonly ESC=""
    readonly BOLD=""
    readonly GREEN=""
    readonly RED=""
    readonly BLUE=""
fi

declare -A NIXCHANNELS

while read -r name url; do
    # Skip empty lines or lines missing a name
    [[ -z "$url" || -z "$name" ]] && continue

    # Assign the url to the name index
    NIXCHANNELS["$name"]="$url"
done < <(sudo -H nix-channel --list)

LOCAL_NIXPKGSREVISION=$(curl -LIs -o /dev/null -w '%{url_effective}' "${NIXCHANNELS['nixpkgs-good']}" | sed -e 's/.*[\./]//')

# Get the git revision from the effective URL of the nixpkgs channel
REMOTE_NIXPKGSREVISION=$(curl -LIs -o /dev/null -w '%{url_effective}' "${NIXCHANNELS['nixpkgs-latest']}" | sed -e 's/.*[\./]//')
LOCAL_NIXPKGSREVISION=${LOCAL_NIXPKGSREVISION:0:${#REMOTE_NIXPKGSREVISION}}

WORKFILE=~/.working-nixpkgs
NONWORKFILE=~/.nonworking-nixpkgs
if [[ "$LOCAL_NIXPKGSREVISION" == "$REMOTE_NIXPKGSREVISION" ]]; then
    printf "%s=== Local nixpkgs version is up-to-date with nixpkgs-unstable channel ===%s\n" "$GREEN$BOLD" "$ESC"
    printf "%s==>%s  LOCAL_REVISION :: %s\n" "$BLUE$BOLD" "$ESC" "$LOCAL_NIXPKGSREVISION"
else
    WARNREV=
    if test -e $NONWORKFILE &&
        grep -q "^$REMOTE_NIXPKGSREVISION$" $NONWORKFILE &&
        ! (test -e $WORKFILE &&
            grep -q "^$REMOTE_NIXPKGSREVISION$" $WORKFILE); then
        WARNREV="(Failed last darwin-rebuild)"
    fi
    printf "%s*** New version detected on nixpkgs-unstable channel ***%s\n" "$GREEN$BOLD" "$ESC" >&"$OUTPUT"
    printf "%s==>%s  LOCAL_REVISION :: $(get_conditional_substring "$LOCAL_NIXPKGSREVISION" 10)\n" "$BLUE$BOLD" "$ESC" >&"$OUTPUT"
    printf "%s==>%s  REMOTE_REVISION:: $(get_conditional_substring "$REMOTE_NIXPKGSREVISION" 10) %s%s\n" "$BLUE$BOLD" "$RED$BOLD" "$WARNREV" "$ESC" >&"$OUTPUT"
fi

unset 'NIXCHANNELS["nixpkgs"]'
unset 'NIXCHANNELS["nixpkgs-good"]'
unset 'NIXCHANNELS["nixpkgs-latest"]'

## Compute the maximum length of channel name
max_namelen=0
for channame in "${!NIXCHANNELS[@]}"; do
    pkgpath=$(readlink -f ~/.nix-defexpr/channels_root/"$channame")
    [[ -z ${pkgpath+x} ]] && continue

    len=${#channame}

    if ((len > max_namelen)); then
        max_namelen=$len
    fi
done
# Add length of _remote_hash
((max_namelen = max_namelen + $(echo -n "_remote_hash" | wc -m)))

echo ""
echo "==============="
for channame in "${!NIXCHANNELS[@]}"; do
    pkgpath=$(readlink -f ~/.nix-defexpr/channels_root/"$channame")
    if [[ ! -z ${pkgpath+x} ]]; then
        pkgurl=${NIXCHANNELS[$channame]}

        lhash=$(nix-hash --base32 --type sha256 "$pkgpath"/)
        rhash=$(nix-prefetch-url --unpack --type sha256 "$pkgurl" 2>/dev/null)

        if [[ "$lhash" != "$rhash" ]]; then
            printf "%s*** New package detected on %s channel ***%s\n" "$GREEN$BOLD" "$channame" "$ESC" >&"$OUTPUT"
            printf "%s==>%s  %-*s: $(get_conditional_substring "$lhash" 8)\n" "$BLUE$BOLD" "$ESC" "$max_namelen" "${channame}_local_hash" >&"$OUTPUT"
            printf "%s==>%s  %-*s: $(get_conditional_substring "$rhash" 8)\n" "$BLUE$BOLD" "$RED$BOLD" "$max_namelen" "${channame}_remote_hash" "$ESC" >&"$OUTPUT"
        else
            printf "%s=== Local package is up-to-date with %s channel ===%s\n" "${GREEN}${BOLD}" "$channame" "$ESC"
            printf "%s==>%s  %-*s: %s\n" "$BLUE$BOLD" "$ESC" "$max_namelen" "${channame}_local_hash" "$lhash"
        fi
    else
        printf "%s!!!Cannot find local installed package detected for channel %s\n" "$RED$BOLD" "$channame${ESC}" >&2
    fi
done

# Perform homebrew check for outdated packages
brew update >/dev/null 2>&1
BREWOUTDATED=$(brew outdated)
if [ -n "$BREWOUTDATED" ]; then
    echo ""
    printf "%s*** Outdated homebrew packages ***%s\n" "$GREEN$BOLD" "$ESC" >&"$OUTPUT"
    while IFS= read -r line; do
        printf "%s==>%s  %s\n" "$BLUE$BOLD" "$RED$BOLD" "$line${ESC}" >&"$OUTPUT"
    done <<<"$BREWOUTDATED"
fi

if [ "$OUTPUT" -ne 2 ]; then
    # Execute checktermperms only if not running in launchdagent
    SCRIPTNAME=$(readlink -f "$0")
    SCRIPTDIR=$(dirname "$SCRIPTNAME")
    echo ""
    echo "==============="
    "$SCRIPTDIR/checktermperms.sh"
fi
