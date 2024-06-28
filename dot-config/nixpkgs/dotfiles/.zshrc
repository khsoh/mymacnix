
if [ -z "${TERMINFO_DIRS}" ]; then
    export TERMINFO_DIRS=/usr/share/terminfo
fi
export TERMINFO_DIRS=$TERMINFO_DIRS:$HOME/.local/share/terminfo
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}


# Use vi mode for editing commandline
export EDITOR=vim

tmux () {
    [ -x ~/.config/tmux/setup_terminal_font.zsh ] && ~/.config/tmux/setup_terminal_font.zsh
    if [[ -z $1 ]]; then
        command /run/current-system/sw/bin/tmux new-session -A
        resize_terminal
    else
        command /run/current-system/sw/bin/tmux $@
    fi
}

## Resizes the terminal window
# By default, if no arguments given, it resizes terminal in main display 
# to half-width and full-height
# Otherwise, the 2 arguments are the fractional width and height of the main
# display.
resize_terminal() {
	XFRACTION=${1:-0.5}
	YFRACTION=${2:-1}

	## Get the main display resolution
	NIXRUNPATH=/run/current-system/sw/bin
	JQ=$NIXRUNPATH/jq
	SED=$NIXRUNPATH/sed
	DISPJS=$(system_profiler SPDisplaysDataType -json|$JQ '.SPDisplaysDataType')
	if [[ $(echo $DISPJS|$JQ 'length') -gt 0 ]]; then
		eval $(echo $DISPJS | $JQ '.[0].spdisplays_ndrvs.[] | select (.spdisplays_main == "spdisplays_yes") | ._spdisplays_resolution' | $SED -rn 's/"([0-9]+)\s*x\s*([0-9]+).*$/BOTRIGHTX=\1;BOTRIGHTY=\2/p')

		## Compute the coordinates to position the terminal window in the main display.
		## So, this works properly even in a multi-monitor setup.
		TOPLEFTX=0
		TOPLEFTY=0

		osascript <<-EOF
		tell application "Terminal"
			set winID to id of window 1
			set botrx to ($BOTRIGHTX * $XFRACTION) as integer
			set botry to ($BOTRIGHTY * $YFRACTION) as integer
			set bounds of window id winID to {$TOPLEFTX, $TOPLEFTY, botrx, botry}
		end tell
		EOF
	else
		## The following code is needed for VM installation because
		## SPDisplaysDataType is absent from system_profiler for VMs
		osascript <<-EOF
		tell application "Terminal"
			set winID to id of window 1
			tell application "Finder"
				set terminalSize to bounds of window of desktop
			end tell
			set item 3 of terminalSize to (item 3 of terminalSize * $XFRACTION) as integer
			set item 4 of terminalSize to (item 4 of terminalSize * $YFRACTION) as integer
			set bounds of window id winID to terminalSize
		end tell
		EOF
	fi
}

delagent () {
    if [ -z $1 ]; then
        echo "Usage: delagent <service-target>" >&2
        return 1
    fi
    launchctl bootout gui/$UID/$1
}

# vim mode config
# ---------------

# Activate vim mode.
bindkey -v

# Remove mode switching delay.
KEYTIMEOUT=5

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'

  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

# Use beam shape cursor on startup.
echo -ne '\e[5 q'

# Use beam shape cursor for each new prompt.
preexec() {
   echo -ne '\e[5 q'
}

_fix_cursor() {
   echo -ne '\e[5 q'
}

precmd_functions+=(_fix_cursor)
