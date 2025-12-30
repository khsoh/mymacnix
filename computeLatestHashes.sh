#!/run/current-system/sw/bin/zsh

## This script gets the latest commit hash of the main/master branch of the repos
## referenced in home.nix and computes the SRI SHA256 checksum for each repo

nix-instantiate --eval --json --strict -E "
  let
    config = (import <darwin> { }).config;
    files = config.home-manager.users.\"$(id -un)\".home.file;
  in
    builtins.mapAttrs (name: value: {
      owner = value.source.owner or null;
      repo = value.source.repo or null;
    }) files
" | jq -r 'to_entries[] | select(.value.repo != null) | "https://github.com/\(.value.owner)/\(.value.repo)"' \
    | while IFS= read -r repo; do
    rev=$(git ls-remote $repo HEAD|awk '{print $1}')
    hash=$(nix --experimental-features nix-command hash convert --hash-algo sha256 --to sri $(nix-prefetch-url --unpack $repo/archive/${rev}.tar.gz 2> /dev/null))
    printf "REPO=$repo\nrev=\"$rev\";\nsha256=\"$hash\";\n\n"
done

