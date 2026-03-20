#!/usr/bin/env zsh

## This script gets the latest commit hash of the HEAD at the main/master of the repos
## referenced in home.nix and computes the SRI SHA256 checksum for each repo
## The outputs can then be used to replace the corresponding entries in the home.nix file

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

  nix-prefetch-github $owner $repo
done

