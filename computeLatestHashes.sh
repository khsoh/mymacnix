#!/usr/bin/env zsh

## This script gets the latest commit hash of the HEAD at the main/master of the repos
## referenced in home.nix and computes the SRI SHA256 checksum for each repo
## The outputs can then be used to replace the corresponding entries in the home.nix file

function cleanup() {
  if [ -n "$ULIMIT" ]; then
    ulimit -n $ULIMIT
  fi
}

trap cleanup EXIT INT TERM QUIT

ULIMIT=$(ulimit -n)
ulimit -n 4096
nix-instantiate --eval --json -E --raw "
  let
    config = (import <darwin> { }).config;
    lib = (import <nixpkgs> { }).lib;
    _files = config.home-manager.users.\"$(id -un)\".home.file;
    # Get only fetchFromGitHub files
    ghfiles = lib.attrsets.filterAttrs (n: v: v.source ? githubBase) _files;
  in
    lib.concatLines (lib.attrsets.mapAttrsToList (name: value:
      \"\${value.source.owner}:\${value.source.repo}\"
      ) ghfiles)
" | while IFS=':' read -r owner repo; do
  # Skip empty lines or lines that do not match the format
  [[ -z "$owner" || -z "$repo" ]] && continue

  ## Run the alias for this command
  # nix-prefetch-github --nix $owner $repo | tail -n +4 | sed -e 's/pkgs.fetchFromGitHub {/{/'
  nx-pfgh $owner $repo
done

