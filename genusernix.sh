#!/usr/bin/env bash

if [ -e ~/.config/nixpkgs/darwin/_user.nix ]; then
    exit 0
fi
cat <<EOF > ~/.config/nixpkgs/darwin/_user.nix
{
    name = "$(id -un)";
    home = "$(python -c 'import os; print(os.path.expanduser("~"))')";
    uid = $(id -u);
}
EOF
