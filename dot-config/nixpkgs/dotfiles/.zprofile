if [ -r ~/.zshrc ]; then
    source ~/.zshrc
fi
if [[ ! -e /Applications/1Password.app/Contents/MacOS/op-ssh-sign && -n $SSH_AUTH_SOCK ]]; then
    if ! ssh-add -l; then
        [ -f ~/.ssh/nixid_ed25519 ] && ssh-add ~/.ssh/nixid_ed25519
    fi
fi
