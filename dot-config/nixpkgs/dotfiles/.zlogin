
## Display current version of nixpkgs and latest version when TMUX window is open
if [[ -o interactive && -n $TMUX ]]; then
    echo "Please wait for printing out local and remote versions of nixpkgs..."
    echo "Local version of nixpkgs: $(darwin-version --darwin-label)"
    echo "Remote version of nixpkgs: $(NIX_PATH=nixpkgs=channel:nixpkgs-unstable nix-instantiate --eval --expr "(import <nixpkgs> {}).lib.version"|sed -e 's/"//g')"
fi

