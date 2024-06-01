if [ -r ~/.zshrc ]; then
    source ~/.zshrc
fi
[[ -e "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
