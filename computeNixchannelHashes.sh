#!/run/current-system/sw/bin/bash

## Declare the channels that are declared in root (excluding nixpkgs)
##   **** Requires user login to access root account
declare -A NIXCHANNELS
eval "$(sudo -i nix-channel --list|grep -v "^nixpkgs" | awk 'BEGIN { OFS="" } { print "NIXCHANNELS[",$1,"]=",$2 }')"

## Add channels defined for this local user
eval "$(nix-channel --list|awk 'BEGIN { OFS="" } { print "NIXCHANNELS[",$1,"]=",$2 }')"

for pkg in "${!NIXCHANNELS[@]}"; do
  pkgpath=$(readlink -f "$(nix-instantiate --eval --expr """<${pkg}>""")")
  if [[ ! -z ${pkgpath+x} ]]; then
      pkgurl=${NIXCHANNELS[$pkg]}

      lastrhash=$(/usr/bin/grep "^${pkg}_remote_hash:\s\+" ~/log/checknixchannelsError.log | tail -1 | sed -n -e 's/^${pkg}_remote_hash:\s\+//p')
      lhash=$(nix-hash --base32 --type sha256 $pkgpath/)
      rhash=$(nix-prefetch-url --unpack --type sha256 $pkgurl 2> /dev/null)

      if [[ "$lhash" != "$rhash" ]]; then
	echo "***New package detected for update on $pkg channel:"
	echo "${pkg}_local_hash:  $lhash"
	echo "${pkg}_remote_hash: $rhash"
      else
	echo "Local package is up-to-date with $pkg channel"
	echo "${pkg}_local_hash:  $lhash"
      fi
  else
    echo "!!!Cannot find local installed package for channel $pkg"
  fi
done

