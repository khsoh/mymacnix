if [ -r ~/.bashrc ]; then
  source ~/.bashrc
fi
[[ -e "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

if [ -z "${TERMINFO_DIRS}" ]; then
    export TERMINFO_DIRS=/usr/share/terminfo
fi
export TERMINFO_DIRS=$TERMINFO_DIRS:$HOME/.local/share/terminfo

export PATH=/usr/local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin

