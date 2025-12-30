#!/run/current-system/sw/bin/zsh

## This script gets the latest commit hash of the main/master branch of the repos
## referenced in home.nix and computes the SRI SHA256 checksum for each repo

nix-instantiate --eval --json --strict -E --raw "
  let
    config = (import <darwin> { }).config;
    lib = (import <nixpkgs> { }).lib;
    _files = config.home-manager.users.\"$(id -un)\".home.file;
    # Get only fetchFromGitHub files
    ghfiles = lib.attrsets.filterAttrs (n: v: v.source ? githubBase) _files;
  in
    lib.concatLines (lib.attrsets.mapAttrsToList (name: value:  \"https://\" +
      value.source.githubBase + \"/\" +
      value.source.owner + \"/\" +
      value.source.repo
      ) ghfiles)
" | while IFS= read -r repo; do
    rev=$(git ls-remote $repo HEAD|awk '{print $1}')
    hash=$(nix --experimental-features nix-command hash convert --hash-algo sha256 --to sri $(nix-prefetch-url --unpack $repo/archive/${rev}.tar.gz 2> /dev/null))
    printf "REPO=$repo\nrev=\"$rev\";\nsha256=\"$hash\";\n\n"
done

