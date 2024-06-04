alias pip=/usr/local/bin/pip3

# Use vi-mode for command line editing
export EDITOR=vim
set -o vi

tmux () {
    [ -x ~/.config/tmux/setup_terminal_font.zsh ] && ~/.config/tmux/setup_terminal_font.zsh
    if [[ -z $1 ]]; then
        if [[ $(command tmux list-session 2>&/dev/null) ]]; then
            command tmux switch-client -t $(command tmux new-session -d -P)
        else
            command tmux new-session -A
        fi
    else
        command tmux $@
    fi
}
