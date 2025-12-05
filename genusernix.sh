#!/usr/bin/env bash

cat <<EOF > ~/.config/nixpkgs/darwin/user.nix
{
    name = "$(id -un)";
    home = "$(python -c 'import os; print(os.path.expanduser("~"))')";
    uid = $(id -u);
}
EOF
