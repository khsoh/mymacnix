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
#REMOTE_NIXPKGSREVISION=$(curl -s $(curl -Ls -o /dev/null -w %{url_effective} ${NIXCHANNELS["nixpkgs"]})/git-revision)
REMOTE_NIXPKGSREVISION=$(output=$(curl -Lsf -o /dev/null -w %{url_effective} ${NIXCHANNELS["nixpkgs"]}) && echo "$output" | sed 's/.*\.//')

if [[ ${LOCAL_NIXPKGSREVISION:0:${#REMOTE_NIXPKGSREVISION}} == $REMOTE_NIXPKGSREVISION ]]; then
  echo "Local nixpkgs version is up-to-date with nixpkgs-unstable channel"
  echo "  LOCAL_REVISION:: ${LOCAL_NIXPKGSREVISION:0:${#REMOTE_NIXPKGSREVISION}}"
else
  WARNREV=
  if test -e ~/.nonworking-nixpkgs && 
      grep -q "^$REMOTE_NIXPKGSREVISION$" ~/.nonworking-nixpkgs &&
      ! (test -e ~/.working-nixpkgs && 
      grep -q "^$REMOTE_NIXPKGSREVISION$" ~/.working-nixpkgs) ; then
    WARNREV="(Failed last darwin-rebuild)"
  fi
  echo "***New nixpkgs version detected for update on nixpkgs-unstable channel" >&"$OUTPUT"
  echo "  LOCAL_REVISION:: ${LOCAL_NIXPKGSREVISION:0:${#REMOTE_NIXPKGSREVISION}}" >&"$OUTPUT"
  echo "  REMOTE_REVISION:: $REMOTE_NIXPKGSREVISION $WARNREV" >&"$OUTPUT"
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
      echo "  ${pkg}_local_hash:  $lhash" >&"$OUTPUT"
      echo "  ${pkg}_remote_hash: $rhash" >&"$OUTPUT"
    else
      echo "Local package is up-to-date with $pkg channel"
      echo "  ${pkg}_local_hash:  $lhash"
    fi
  else
    echo "!!!Cannot find local installed package detected for channel $pkg" >&2
  fi
done

