#!/run/current-system/sw/bin/bash

REMOTE_VERSION=$(NIX_PATH=nixpkgs=channel:nixpkgs-unstable nix-instantiate --eval --expr "(import <nixpkgs> {}).lib.version"|sed -e 's/"//g')
LOCAL_NIXPKGSREVISION=$(darwin-version --json|jq -r ".nixpkgsRevision")
REMOTE_NIXPKGSREVISION=${REMOTE_VERSION##*.}

if [[ ${LOCAL_NIXPKGSREVISION:0:${#REMOTE_NIXPKGSREVISION}} == $REMOTE_NIXPKGSREVISION ]]; then
  echo "Local nixpkgs version is up-to-date with nixpkgs-unstable channel"
  echo "  LOCAL_REVISION:: ${LOCAL_NIXPKGSREVISION:0:${#REMOTE_NIXPKGSREVISION}}"
else
  echo "***New nixpkgs version detected for update on nixpkgs-unstable channel"
  echo "  LOCAL_REVISION:: ${LOCAL_NIXPKGSREVISION:0:${#REMOTE_NIXPKGSREVISION}}"
  echo "  REMOTE_VERSION:: $REMOTE_NIXPKGSREVISION"
fi

declare -A NIXCHANNELS

eval "$(sudo nix-channel --list 2>/dev/null|grep -v "^nixpkgs"|awk 'BEGIN { OFS="" } { print "NIXCHANNELS[",$1,"]=",$2 }')"

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

