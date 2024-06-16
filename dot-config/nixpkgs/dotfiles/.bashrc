alias pip=/usr/local/bin/pip3

# Use vi-mode for command line editing
export EDITOR=vim
set -o vi

tmux () {
    [ -x ~/.config/tmux/setup_terminal_font.zsh ] && ~/.config/tmux/setup_terminal_font.zsh
    if [[ -z $1 ]]; then
        nsparam="-A"
        if [[ $(command tmux list-session 2>&/dev/null) ]]; then
            nsparam=""
        fi
        osascript -e '
        tell application "Terminal"
            if not application "Terminal" is running then launch
            do script "tmux new-session '"${nsparam}"'" in window 1
        end tell
        '
    else
        command tmux $@
    fi
}
