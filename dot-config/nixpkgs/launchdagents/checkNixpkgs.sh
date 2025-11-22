#!/usr/bin/env bash

declare -A NIXCHANNELS

eval "$(awk 'BEGIN { OFS="" } { print "NIXCHANNELS[",$2,"]=",$1 }' /etc/nix-channels/system-channels)"

LOCAL_NIXPKGSREVISION=$(darwin-version --json|jq -r ".nixpkgsRevision")

# Get the git revision from the effective URL of the nixpkgs channel
# Another method is to read the git-revision file within that URL (this requires downloading the file).
#REMOTE_NIXPKGSREVISION=$(curl -s $(curl -Ls -o /dev/null -w %{url_effective} ${NIXCHANNELS["nixpkgs"]})/git-revision)
REMOTE_NIXPKGSREVISION=$(curl -Ls -o /dev/null -w %{url_effective} ${NIXCHANNELS["nixpkgs"]} | sed 's/.*\.//')

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
  echo "***New nixpkgs version detected for update on nixpkgs-unstable channel" >&2
  echo "  LOCAL_REVISION:: ${LOCAL_NIXPKGSREVISION:0:${#REMOTE_NIXPKGSREVISION}}" >&2
  echo "  REMOTE_REVISION:: $REMOTE_NIXPKGSREVISION $WARNREV" >&2
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
      echo "***New package detected for update on $pkg channel:" >&2
      echo "  ${pkg}_local_hash:  $lhash" >&2
      echo "  ${pkg}_remote_hash: $rhash" >&2
    else
      echo "Local package is up-to-date with $pkg channel"
      echo "  ${pkg}_local_hash:  $lhash"
    fi
  else
    echo "!!!Cannot find local installed package detected for channel $pkg" >&2
  fi
done

