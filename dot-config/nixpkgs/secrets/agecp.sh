#!/usr/bin/env bash

#!/usr/bin/env bash

# Define paths (adjust if yours are in non-standard locations)
#CONFIG_FILE="$HOME/.nixpkgs/darwin-configuration.nix"
USER_NAME="$(whoami)"
SOURCE_NAME="$1"
SECRET_NAME="$2"

if [ ! -f "$SOURCE_NAME" ]; then
    echo "Source file $SOURCE_NAME does not exist"
    exit 1
fi

# Evaluate the configuration to extract the secret's attributes
# We access the secret via: config.home-manager.users.<username>.age.secrets.<name>
SECRET_SOURCE=$(nix-instantiate --eval --strict --json --expr "
  let
    pkgs = import <nixpkgs> { system = builtins.currentSystem; };
    evalDarwin = import <darwin/eval-config.nix>;

    eval = evalDarwin {
      lib = pkgs.lib;
      modules = [ 
        <darwin-config> 
        { nixpkgs.pkgs = pkgs; }
      ];
    };
    secretFile = eval.config.home-manager.users.\"$USER_NAME\".age.secrets.\"$SECRET_NAME\".file;
  in toString secretFile
" 2>/dev/null)

if [ "$?" -ne 0 ]; then
    echo "age.secrets.\"$SECRET_NAME\" attribute not defined in home-manager module"
    exit 1
fi

LOCAL_PATH=$(echo "$SECRET_SOURCE" | tr -d '"')
SECRET_PATH=$(dirname "$LOCAL_PATH")

# Copy and encrypt the source file
pushd $SECRET_PATH >/dev/null
cat "$SOURCE_NAME" | EDITOR='cp /dev/stdin' agenix -e "$(basename $LOCAL_PATH)"
popd >/dev/null


