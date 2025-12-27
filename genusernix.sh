#!/usr/bin/env bash

_USERINFO=$(cat <<EOF
{
    name = "$(id -un)";
    home = "$(python -c 'import os; print(os.path.expanduser("~"))')";
    uid = $(id -u);
}
EOF
)
_USERNIX=~/.config/nixpkgs/darwin/_user.nix

if [[ -f $_USERNIX ]] && diff $_USERNIX <(echo "$_USERINFO") >/dev/null ; then
    exit 0
fi

echo "Auto-generating $_USERNIX file"
echo "$_USERINFO" > $_USERNIX
