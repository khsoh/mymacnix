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
        echo $value
    else
        echo ${value:0:$len}
    fi
}

if [ "$OUTPUT" -eq 1 ]; then
    # Your login-shell-specific logic
    while getopts ":k" opt; do
        case ${opt} in
            k)
                # Kickstart the daemon
                launchctl kickstart gui/$(id -u)/org.nixos.detectNixUpdates
                exit 0
                ;;
            \?)
                # Handle invalid option
                echo "Error: Invalid option: -${OPTARG}" >&2
                exit 1
                ;;
        esac
    done
fi


declare -A NIXCHANNELS

eval "$(awk 'BEGIN { OFS="" } { print "NIXCHANNELS[",$2,"]=",$1 }' /etc/nix-channels/system-channels)"

LOCAL_NIXPKGSREVISION=$(darwin-version --json|jq -r ".nixpkgsRevision")

# Get the git revision from the effective URL of the nixpkgs channel
# Another method is to read the git-revision file within that URL (this requires downloading the file).
REMOTE_NIXPKGSREVISION=$(curl -s $(curl -Ls -o /dev/null -w %{url_effective} ${NIXCHANNELS["nixpkgs"]})/git-revision)
#REMOTE_NIXPKGSREVISION=$(output=$(curl -Lsf -o /dev/null -w %{url_effective} ${NIXCHANNELS["nixpkgs"]}) && echo "$output" | sed 's/.*\.//')
LOCAL_NIXPKGSREVISION=${LOCAL_NIXPKGSREVISION:0:${#REMOTE_NIXPKGSREVISION}}

WORKFILE=~/.working-nixpkgs
NONWORKFILE=~/.nonworking-nixpkgs
if [[ $LOCAL_NIXPKGSREVISION == $REMOTE_NIXPKGSREVISION ]]; then
  echo "Local nixpkgs version is up-to-date with nixpkgs-unstable channel"
  echo "  LOCAL_REVISION:: $LOCAL_NIXPKGSREVISION"
else
  WARNREV=
  if test -e $NONWORKFILE && 
      grep -q "^$REMOTE_NIXPKGSREVISION$" $NONWORKFILE &&
      ! (test -e $WORKFILE && 
      grep -q "^$REMOTE_NIXPKGSREVISION$" $WORKFILE) ; then
    WARNREV="(Failed last darwin-rebuild)"
  fi
  echo "***New nixpkgs version detected for update on nixpkgs-unstable channel" >&"$OUTPUT"
  echo "  LOCAL_REVISION:: $(get_conditional_substring $LOCAL_NIXPKGSREVISION 10)" >&"$OUTPUT"
  echo "  REMOTE_REVISION:: $(get_conditional_substring $REMOTE_NIXPKGSREVISION 10) $WARNREV" >&"$OUTPUT"
fi

unset 'NIXCHANNELS["nixpkgs"]'

echo ""
echo "==============="
for pkg in "${!NIXCHANNELS[@]}"; do
  pkgpath=$(readlink -f ~/.nix-defexpr/channels_root/$pkg)
  if [[ ! -z ${pkgpath+x} ]]; then
    pkgurl=${NIXCHANNELS[$pkg]}

    lhash=$(nix-hash --base32 --type sha256 $pkgpath/)
    rhash=$(nix-prefetch-url --unpack --type sha256 $pkgurl 2> /dev/null)

    if [[ "$lhash" != "$rhash" ]]; then
      echo "***New package detected for update on $pkg channel:" >&"$OUTPUT"
      echo "  ${pkg}_local_hash:  $(get_conditional_substring $lhash 8)" >&"$OUTPUT"
      echo "  ${pkg}_remote_hash: $(get_conditional_substring $rhash 8)" >&"$OUTPUT"
    else
      echo "Local package is up-to-date with $pkg channel"
      echo "  ${pkg}_local_hash:  $lhash"
    fi
  else
    echo "!!!Cannot find local installed package detected for channel $pkg" >&2
  fi
done

# Perform homebrew check for outdated packages
brew update > /dev/null 2>&1
BREWOUTDATED=$(brew outdated)
if [ -n "$BREWOUTDATED" ]; then
    echo ""
    echo "Outdated homebrew packages:" >&"$OUTPUT"
    echo "$BREWOUTDATED" >&"$OUTPUT"
fi

declare -A kitty_perms

while IFS='|' read -r service client auth_value; do
    kitty_perms[$service]=$auth_value
done < <(sudo sqlite3 --readonly /Library/Application\ Support/com.apple.TCC/TCC.db \
    "SELECT service, client, auth_value FROM access WHERE client LIKE '%net.kovidgoyal.kitty%';")

for svc in "${!kitty_perms[@]}"; do
    if [ ${kitty_perms[$svc]} -ne 2 ]; then
        echo "$svc permission for kitty is disabled" >&"$OUTPUT"
    else
        echo "$svc permission for kitty is enabled"
    fi
done
