if [ -r ~/.bashrc ]; then
  source ~/.bashrc
fi

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -z "${TERMINFO_DIRS}" ]; then
    export TERMINFO_DIRS=/usr/share/terminfo
fi
export TERMINFO_DIRS=$TERMINFO_DIRS:$HOME/.local/share/terminfo

