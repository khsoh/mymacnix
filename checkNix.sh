#!/run/current-system/sw/bin/bash

NIXDARWIN_VERSION=$(darwin-version --darwin-label)
REMOTE_VERSION=$(NIX_PATH=nixpkgs=channel:nixpkgs-unstable nix-instantiate --eval --expr "(import <nixpkgs> {}).lib.version"|sed -e 's/"//g')
LOCAL_VERSION=${NIXDARWIN_VERSION%%+?*}
LOCAL_NIXPKGSREVISION=$(darwin-version --json|jq -r ".nixpkgsRevision")
REMOTE_DARWIN_VERSION=${REMOTE_VERSION%%pre*}
REMOTE_NIXPKGSREVISION=${REMOTE_VERSION##*.}
XLOCAL_DESC=LOCAL_VERSION
XLOCAL_VERSION=$LOCAL_VERSION
if [[ $LOCAL_VERSION == $REMOTE_DARWIN_VERSION ]]; then
  XLOCAL_VERSION=$LOCAL_VERSION.$LOCAL_NIXPKGSREVISION
  XLOCAL_DESC=LOCAL_VERSION.LOCAL_NIXPKGSREVISION
fi

if [[ $LOCAL_VERSION == $REMOTE_VERSION || ($LOCAL_VERSION == $REMOTE_DARWIN_VERSION && $LOCAL_NIXPKGSREVISION == $REMOTE_NIXPKGSREVISION*) ]]; then
  echo "Local nixpkgs version is up-to-date with nixpkgs-unstable channel"
  echo "  $XLOCAL_DESC::  $XLOCAL_VERSION"
else
  echo "***New nixpkgs version detected for update on nixpkgs-unstable channel"
  echo "  $XLOCAL_DESC::  $XLOCAL_VERSION"
  echo "  REMOTE_VERSION:: $REMOTE_VERSION"
fi

declare -A NIXCHANNELS

eval "$(nix-channel --list|awk 'BEGIN { OFS="" } { print "NIXCHANNELS[",$1,"]=",$2 }')"

echo ""
echo "==============="
for pkg in "${!NIXCHANNELS[@]}"; do
  pkgpath=$(readlink -f $(nix-instantiate --eval --expr "<${pkg}>"))
  if [[ ! -z ${pkgpath+x} ]]; then
    pkgurl=${NIXCHANNELS[$pkg]}

    lhash=$(nix-hash --base32 --type sha256 $pkgpath/)
    rhash=$(nix-prefetch-url --unpack --type sha256 $pkgurl 2> /dev/null)

    if [[ "$lhash" != "$rhash" ]]; then
      echo "***New package detected for update on $pkg channel:"
      echo "  ${pkg}_local_hash:  $lhash"
      echo "  ${pkg}_remote_hash: $rhash"
    else
      echo "Local package is up-to-date with $pkg channel"
      echo "  ${pkg}_local_hash:  $lhash"
    fi
  else
    echo "!!!Cannot find local installed package detected for channel $pkg"
  fi
done

