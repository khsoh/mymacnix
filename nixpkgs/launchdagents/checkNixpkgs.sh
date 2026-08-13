#!/usr/bin/env zsh

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

get_gitrevision() {
    curl -sIL --connect-timeout 20 \
        --retry 3 \
        --retry-delay 10 \
        --retry-connrefused \
        -o /dev/null -w '%{url_effective}' "$1" | sed -e 's/.*[\./]//'
}

get_atominfo() {
    curl -sL --connect-timeout 20 \
        --retry 3 \
        --retry-delay 10 \
        --retry-connrefused \
        "$1" | \
        xmllint --xpath '//*[local-name()="entry"][1]/*[local-name()="id"]/text()' - | \
        sed -E 's/.*Commit\///' | \
        xargs
}

is_running_under_login
OUTPUT=$?

function cleanup() {
    printf "$ESC"
}

# Create hash directory
NIXBUILD=~/.cache/nixbld_status
mkdir -p $NIXBUILD

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

NIXCHINFO=()

## Compute the maximum length of channel name
max_namelen=0
while read -r name url; do
    # Skip empty lines or lines missing a name
    [[ -z "$url" || -z "$name" ]] && continue

    pkgpath=$(readlink -f ~/.nix-defexpr/channels_root/"$name")
    [[ -z ${pkgpath+x} ]] && continue

    len=${#name}

    if ((len > max_namelen)); then
        max_namelen=$len
    fi

    # Compute the feed
    if [[ "$url" =~ github\.com ]]; then
        # Clean URL and strip tracking prefixes/extensions
        CLEAN_PATH=$(echo "$url" | sed -E 's|https://github.com/||' | sed 's|/archive/|/|')

        OWNER=$(echo "$CLEAN_PATH" | cut -d'/' -f1)
        REPO=$(echo "$CLEAN_PATH" | cut -d'/' -f2)

        # Strip trailing package extensions (.tar.gz or .zip) from the branch segment
        BRANCH=$(echo "$CLEAN_PATH" | cut -d'/' -f3 | sed -E 's/\.(tar\.gz|zip)//')

        FEED_URL="https://github.com/${OWNER}/${REPO}/commits/${BRANCH}.atom"
        NIXCHINFO+=("$name $FEED_URL")
    elif [[ "$url" =~ nixos\.org ]]; then
        # This regex isolates the trailing identifier (e.g., nixpkgs-unstable) regardless of the domain prefix
        CHANNEL_NAME=$(echo "$url" | sed -E 's|https://(channels\.)?nixos\.org(/channels)?/||' | sed 's|/||g')

        FEED_URL="https://github.com/NixOS/nixpkgs/commits/${CHANNEL_NAME}.atom"

        ## nixpkgs channel is inserted at the top of array
        NIXCHINFO=("$name $FEED_URL" "${NIXCHINFO[@]}")
    else
        printf "${BOLD}${RED}===> Channel $name: Unknown channel format - cannot derive feed${ESC}\n"
        continue
    fi

done < <(sudo -H nix-channel --list)

# Add length of _remote_hash
((max_namelen = max_namelen + $(echo -n "_remote_hash" | wc -m)))

for item in "${NIXCHINFO[@]}"; do
    read channame url <<< "$item"

    # 1. Read the existing hash if it exists
    LOCAL_HASH=""
    if [[ "$channame" == "nixpkgs" ]]; then
        LOCAL_HASH=$(darwin-version --nixpkgs-revision | tr -d '\r\n')
        if [[ -n "$LOCAL_HASH" && ${#LOCAL_HASH} -lt 40 ]]; then
            LONGREV=$(curl -s "https://api.github.com/repos/NixOS/nixpkgs/commits/$LOCAL_HASH" | jq -r '.sha' | tr -d '\r\n')
            if [[ -n "$LONGREV" ]]; then
                LOCAL_HASH="$LONGREV"
            fi
        fi
    else
        LOCAL_HASH=$(valkey-cli -p $VALKEY_PORT hget nixch $channame)
    fi

    # 2. Get the remote commit hash of the channel feed
    REMOTE_HASH=$(get_atominfo "$url")

    # 3. Compare the commit hashes
    if [[ "$LOCAL_HASH" == "$REMOTE_HASH" ]]; then
        printf "${GREEN}${BOLD}=== Local package is up-to-date with $channame channel ===${ESC}\n"
        printf "${BLUE}${BOLD}==>${ESC}  ${(r:$max_namelen:):-${channame}_local_hash}: $LOCAL_HASH\n"
    elif [[ -n "$REMOTE_HASH" ]]; then
        NONWORKFILE=${NIXBUILD}/.nonworking-nixpkgs
        EXTRA=
        if test -e $NONWORKFILE && grep -q "^$REMOTE_HASH$" $NONWORKFILE; then
            EXTRA=" (Failed last darwin-rebuild)"
        fi
        printf "${GREEN}${BOLD}*** New package detected on $channame channel ***${ESC}\n" >&"$OUTPUT"
        printf "${BLUE}${BOLD}==>${ESC}  ${(r:$max_namelen:):-${channame}_local_hash}: $LOCAL_HASH\n" >&"$OUTPUT"
        printf "${BLUE}${BOLD}==>${RED}${BOLD}  ${(r:$max_namelen:):-${channame}_remote_hash}: $REMOTE_HASH${EXTRA}${ESC}\n" >&"$OUTPUT"
    else
        printf "${BOLD}${RED}Could not get commit hash for $channame from $url${ESC}\n"
    fi
done

# Perform homebrew check for outdated packages
brew update >/dev/null 2>&1
BREWOUTDATED=$(brew outdated)
if [[ -n "$BREWOUTDATED" ]]; then
    echo ""
    echo "==============="
    printf "${GREEN}${BOLD}*** Outdated homebrew packages ***${ESC}\n" >&"$OUTPUT"
    while IFS= read -r line; do
        printf "${BLUE}${BOLD}==>${RED}${BOLD}  $line${ESC}\n" >&"$OUTPUT"
    done <<<"$BREWOUTDATED"
fi

if [[ "$OUTPUT" -ne 2 ]]; then
    # Execute checktermperms only if not running in launchdagent
    SCRIPTNAME=$(readlink -f "$0")
    SCRIPTDIR=$(dirname "$SCRIPTNAME")
    echo ""
    echo "==============="
    "$SCRIPTDIR/checktermperms.sh"
fi
