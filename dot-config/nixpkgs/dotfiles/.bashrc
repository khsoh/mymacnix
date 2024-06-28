alias pip=/usr/local/bin/pip3

# Use vi-mode for command line editing
export EDITOR=vim
set -o vi

tmux () {
    [ -x ~/.config/tmux/setup_terminal_font.zsh ] && ~/.config/tmux/setup_terminal_font.zsh
    if [[ -z $1 ]]; then
        resize_terminal
        /run/current-system/sw/bin/tmux new-session -A
    else
        /run/current-system/sw/bin/tmux $@
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
