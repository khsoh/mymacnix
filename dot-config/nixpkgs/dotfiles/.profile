#export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [[ ! -e /Applications/1Password.app/Contents/MacOS/op-ssh-sign && -n $SSH_AUTH_SOCK ]]; then
    if ! ssh-add -l; then
        [ -f ~/.ssh/nixid_ed25519 ] && ssh-add ~/.ssh/nixid_ed25519
    fi
fi
