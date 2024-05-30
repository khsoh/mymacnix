{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs;
    [ vim
      neovim
      tmux
      git
      git-lfs
      git-repo
      gh
      tree
      dhall-json
      stow
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  # programs.fish.enable = true;

  programs.zsh.promptInit = ''
autoload -U colors && colors
autoload -U promptinit && promptinit

# Define own theme

prompt_pex_help() {
  cat <<ENDHELP
This prompt displays the username for the left-hand prompt in white; and the
current working directory for the right-hand prompt in bright green. 

This can be invoked thus:

  prompt pex [L|R]

where the non-zero exit code in bright red is displayed at the right (R) or left (L) prompt.
The default is L if not argument is given
ENDHELP
}

prompt_pex_setup() {
  local dst="''${1:-L}"
  if [[ $dst = "R" ]]; then
    # Put non-zero error code in RHS prompt
    RPROMPT="%{$(tput setaf 10)%}%~%{$reset_color%}%(?..%{$(tput setaf 9)%} [%?]%{$reset_color%})"
    PS1="%n %% "
  elif [[ $dst == "L" ]]; then
    # Put non-zero error code in LHS prompt
    RPROMPT="%{$(tput setaf 10)%}%~%{$reset_color%}"
    PS1="%(?..%{$(tput setaf 9)%}[%?] %{$reset_color%})%n %% "
  else
    exit 1
  fi
}

# Add the theme to promptsys
prompt_themes+=( pex )

# Load the theme
prompt pex L && setopt prompt_sp
  '';

  # Create /etc/bashrc
  programs.bash.enable = true;
  programs.bash.interactiveShellInit = ''
# PROMPT

shopt -s extglob

# Indicate whether to put last command exit code in RHS or LHS prompt
EXITCODE_RHS=0

# default macOS prompt is: \h:\W \u\$

# assemble the right-aligned prompt string 
# - represented as PS1RHS within function
function __build_prompt {
    local EXIT="$?" # store current exit code


    # define some colors
    local RESET=$(printf "\1$(tput sgr0)\2")
    local BTRED=$(printf "\1$(tput setaf 9)\2")
    local BTGREEN=$(printf "\1$(tput setaf 10)\2")

    # Need to add \\ to escape [ for $RESET pattern matching
    local RE_BTRED=''${BTRED//[/\\\\[}  
    local RE_BTGREEN=''${BTGREEN//[/\\\\[}  
    local RE_RESET=''${RESET//[/\\\\[}  
    RE_RESET=''${RE_RESET//\(/\\(}

    # EXIT CODE matching
    local RE_EXITCODE=$(printf "''${RE_BTRED}\\\\[+([0-9])\\\\]''${RE_RESET} ")

    # Remove any pre-existing exit code setting in PS1 prompt
    PS1=''${PS1#''${RE_EXITCODE}}

    # Generate current working directory string
    local PSPATH=''${PWD/#''${HOME}/\~}

    if [[ -z "$IN_NIX_SHELL" ]]; then
      # this is the default prompt for non-Nix setup
      PS1="\u # "
    else
      # Nix-shell - remove \w in PS1 because we already have it at the right prompt
      PS1=''${PS1/:*\\w/}
      # Remove any starting \n
      PS1=''${PS1/#\\n/}
    fi

    # Create a right-aligned prompt in bright GREEN
    printf -v PS1RHS "''${BTGREEN}''${PSPATH}''${RESET} "

    # Print non-zero exit code of the last command in Bright RED
    if [[ $EXIT -ne 0 ]]; then
        if [[ $EXITCODE_RHS -eq 1 ]]; then
          PS1RHS=''${PS1RHS}$(printf "''${BTRED}[''${EXIT}]''${RESET} ")
        else
          PS1=$(printf "''${BTRED}[''${EXIT}]''${RESET} ")$PS1
        fi
    fi

    # Strip ANSI commands before counting length
    local matchstr=$(printf "@(''${RE_RESET}|\1\x1B\\[+(+([0-9])?(;))m\2)")
    local PS1RHS_stripped=''${PS1RHS//''${matchstr}/}

    ### DEBUGGING CODE
    # instr="$PS1RHS_stripped"
    # for ((i = 0 ; i < ''${#instr}; i++)); do
    #     chr="''${instr:i:1}"
    #     ascv=$(printf "%d" "'$chr")
    #     echo "$chr: $ascv"
    # done

    ## colpos positions the cursor at the specified column via \x1B[#G command
    local colpos=$(printf "\1\x1B[%dG\2" $(($(tput cols) - ''${#PS1RHS_stripped} + 1)))
    printf "''${colpos}%s\r" "''${PS1RHS}"
}

# set the prompt command
# include previous values to maintain Apple Terminal support (window title path and sessions)
# this is explained in /etc/bashrc_Apple_Terminal
PROMPT_COMMAND="__build_prompt''${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
  '';

# Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
