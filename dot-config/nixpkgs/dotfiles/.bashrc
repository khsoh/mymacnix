alias pip=/usr/local/bin/pip3

# Use vi-mode for command line editing
export EDITOR=vim
set -o vi

tmux () {
    [ -x ~/.config/tmux/setup_terminal_font.zsh ] && ~/.config/tmux/setup_terminal_font.zsh
    if [[ -z $1 ]]; then
        command /run/current-system/sw/bin/tmux new-session -A
    else
        command /run/current-system/sw/bin/tmux $@
    fi
}
