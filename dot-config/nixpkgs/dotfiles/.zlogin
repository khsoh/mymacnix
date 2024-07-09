
ESC="$(tput sgr0)"
BOLD="$(tput bold)"
GREEN="$(tput setaf 2)"
RED="$(tput setaf 1)"

## Display current version of nixpkgs and latest version when TMUX window is open
if [[ -o interactive && -n $TMUX ]]; then
    echo "Please wait for printing out local and remote versions of nixpkgs..."
    LOCAL_VERSION=$(darwin-version --darwin-label)
    REMOTE_VERSION=$(NIX_PATH=nixpkgs=channel:nixpkgs-unstable nix-instantiate --eval --expr "(import <nixpkgs> {}).lib.version"|sed -e 's/"//g')
    echo "Local version of nixpkgs: $LOCAL_VERSION"
    echo "Remote version of nixpkgs: $REMOTE_VERSION"
    LOCAL_VERSION=${LOCAL_VERSION//+?*/}

    if [[ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]]; then
        printf "${BOLD}${GREEN}Local version matches remote version${ESC}\n"
    else
        printf "${BOLD}${RED}Local version is different from remote version${ESC}\n"
    fi 
fi

