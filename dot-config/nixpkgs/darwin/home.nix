{ config, osConfig, pkgs, lib, ... }:
let
  homecfg = config.home;
  onepasscfg = config.onepassword;
  sshcfg = config.sshkeys;
  ghcfg = config.github;
  glcfg = config.gitlab;

  ## Default git email - will be available to public
  default_git_email = "hju37823@outlook.com";

  pkgInstalled = (name : builtins.elem name 
    (lib.unique (builtins.map lib.getName (osConfig.environment.systemPackages ++ homecfg.packages))));
  nixAppInstalled = (name : builtins.elem name 
    (builtins.map lib.getName osConfig.environment.systemPackages));
in {
  imports = [
    <agenix/modules/age-home.nix>
    ./usermod
  ];

  ##### xdg configuration
  xdg.enable = true;

  ##### agenix configuration
  age.identityPaths = [
    "${sshcfg.NIXIDPKFILE}"
    "${sshcfg.USERPKFILE}"
  ];

  # armored-secrets stores various secret information in JSON file format
  age.secrets."armored-secrets.json" = {
    file = /. + "${config.xdg.configHome}/nixpkgs/secrets/armored-secrets.json.age";

# path should be a string expression (in quotes), not a path expression
# IMPORTANT: READ THE DOCUMENTATION on age.secrets.<name>.path
    path = "${config.xdg.configHome}/nix/armored-secrets.json";

# The default is true if not specified.  We want to make sure that
# the "file" (decrypted secret) is symlinked and not generated directly into
# that location
    symlink = true;

# The following are needed to ensure the decrypted secret has the correct permission
    mode = "600";

# Note that the owner and group attribute are absent from home-manager module
    #owner = "${username}";
    #group = "staff";
  };

  # Stores the Raise2 backup configuration
  age.secrets."mac-raise2.json" = {
    file = /. + "${config.xdg.configHome}/nixpkgs/secrets/mac-raise2.json.age";

# path should be a string expression (in quotes), not a path expression
# IMPORTANT: READ THE DOCUMENTATION on age.secrets.<name>.path
    path = "${homecfg.homeDirectory}/Dygma/mac-raise2.json";

# The default is true if not specified.  We want to make sure that
# the "file" (decrypted secret) is symlinked and not generated directly into
# that location
    symlink = true;

# The following are needed to ensure the decrypted secret has the correct permission
    mode = "600";

# Note that the owner and group attribute are absent from home-manager module
    #owner = "${username}";
    #group = "staff";
  };

  ## User-specific aliases
  home.shellAliases = {
    cdnix = "cd $(readlink -f ${builtins.toString ./.})";
    hbb = "brew bundle";
    hbu = "brew update";
  };

  home.file.resize_app = {
    ## AppleScript file to resize app
    target = "${config.xdg.configHome}/scpt/resize_app.scpt";
    source = ./scpt/resize_app.scpt;
  };

  home.file.waitapp = {
    ## JavaScript (JXA) file to wait for DisplayLink Manager to start
    target = "${config.xdg.configHome}/scpt/waitapp.js";
    source = ./scpt/waitapp.js;
  };

  ## Generate list of public keys file in pubkeys.nix
  home.file."pubkeys.nix" = {
    ## The defaults are commented out
    # enable = true;

    target = ".config/nixpkgs/secrets/pubkeys.nix";
    text = ''
      [
        "${sshcfg.userssh_pubkey}"
        "${sshcfg.nixidssh_pubkey}"
      ]
      '';

  };

  home.file.gitAllowedSigners = {
    ## Generate the allowed signers file
    # enable = true;

    target = ".ssh/allowed_signers";
    text = ''
      ${default_git_email} namespaces="git" ${sshcfg.userssh_pubkey}
      ${default_git_email} namespaces="git" ${sshcfg.nixidssh_pubkey}
      '';
  };

  home.file.tmux = {
    ## The defaults are commented out
    # enable = true;

    target = "${config.xdg.configHome}/tmux";
    #source = ../tmux;
    source = pkgs.fetchFromGitHub {
      owner = ghcfg.username;
      repo = "tmuxconf";
      rev="cd93e8f43024f2527fd673f8397c99bd69497604";
      sha256="sha256-QcOi0RlC4wP23Xfx17K/SIx2QlBgA9jwMnryroDSFCE=";
      #sha256 = lib.fakeSha256;
    };
    recursive = true;
  };

  # home.file.kitty = {
  #   ## The defaults are commented out
  #
  #   # Enable kitty config if kitty is installed in Nix or homebrew
  #   enable = pkgInstalled "kitty" ||
  #     lib.lists.any (cask: cask.name == "kitty") osConfig.homebrew.casks;
  #
  #   target = "${config.xdg.configHome}/kitty";
  #   #source = ../kitty;
  #   source = pkgs.fetchFromGitHub {
  #     owner = ghcfg.username;
  #     repo = "kittyconf";
  #     rev="98fe859b971f83faa2af7741b01ab23f347f544d";
  #     sha256="sha256-95SXw7wdfP1p81eEFOH+wTzhyw25eWrnAFQhZgkVDNA=";
  #     #sha256 = lib.fakeSha256;
  #   };
  #   recursive = true;
  # };
  home.file.kittyStartup = {
    # Enable kitty config if kitty is installed in Nix or homebrew
    enable = pkgInstalled "kitty" ||
      lib.lists.any (cask: cask.name == "kitty") osConfig.homebrew.casks;

    target = "${config.xdg.configHome}/kitty/startup.conf";
    text = ''
cd ~/github
layout splits
launch zsh
launch --location hsplit zsh
launch --type overlay zsh -c "${config.xdg.configHome}/scpt/waitapp.js 'DisplayLink Manager.app' && resize_app kitty"
      '';
  };
  home.file.kittyBackdrop = {
    # Enable kitty config if kitty is installed in Nix or homebrew
    enable = pkgInstalled "kitty" ||
      lib.lists.any (cask: cask.name == "kitty") osConfig.homebrew.casks;
    target = "${config.xdg.configHome}/kitty/totoro-dimmed.jpeg";
    source = ./totoro-dimmed.jpeg;
  };

  home.file.nvim = {
    ## The defaults are commented out
    # enable = true;

    target = "${config.xdg.configHome}/nvim";
    source = pkgs.fetchFromGitHub {
      owner = ghcfg.username;
      repo = "kickstart.nvim";
      rev="52e7d1c81fc9241973bfff6fc16cfa34175270b8";
      sha256="sha256-axmOvvewLPM6nXhByptdw3B8A9o+1ng3hD4kmN9muqw=";
      #sha256 = lib.fakeSha256;
    };
    recursive = true;
  };

  ### Enable bash configuration
  programs.bash = {
    enable = true;
    enableCompletion = false;

    # Written at start of .bashrc
    bashrcExtra = builtins.readFile ./bash/bashrcExtra;

    # Written at end of .bashrc
    initExtra = "";

    sessionVariables = {
      LC_ALL = "en_US.UTF-8";
      LANG = "en_US.UTF-8";
      TERMINFO_DIRS = "\${TERMINFO_DIRS:-/usr/share/terminfo}:$HOME/.local/share/terminfo";
      EDITOR = "nvim";
    };  # Written to start of .profile

    # Written to end of .profile
    profileExtra = builtins.readFile ./bash/profile-extra;
  };

  ### Enable zsh configuration
  programs.zsh = {
    enable = true;

    autocd = true;
    defaultKeymap = "viins";
    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      TERMINFO_DIRS = "\${TERMINFO_DIRS:-/usr/share/terminfo}:$HOME/.local/share/terminfo";
      EDITOR = "nvim";
    };

    profileExtra = builtins.readFile ./zsh/zprofile-extra;
    initContent = builtins.readFile ./zsh/zshrc-initExtra;
    envExtra = builtins.readFile ./zsh/zshenv-extra;
  };

  ### Enable readline configuration
  programs.readline = {
    enable = true;
    includeSystemConfig = false;
    variables = {
      show-mode-in-prompt = true;
      vi-cmd-mode-string = "\"\\1\\e[2 q\\2\"";
      vi-ins-mode-string = "\"\\1\\e[6 q\\2\"";
    };
  };

  ### Enable ssh configuration
  programs.ssh = if onepasscfg.sshsign_pgm_present then
    {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        addKeysToAgent = "no";
        forwardAgent = false;
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      extraConfig = ''
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      '';
    } else {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        addKeysToAgent = "yes";
        forwardAgent = false;
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      extraConfig = ''
        IdentityFile ${sshcfg.NIXIDPKFILE}
      '';
    };

  ### Enable git configuration
  programs.git = {
    enable = true;

    settings = {
      alias = {
        co = "checkout";
        ci = "commit";
        br = "branch";
        st = "status";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        glog = "log --graph --all";
      };
      user = {
        name = "K H Soh";
        email = default_git_email;
      };
      gpg = {
        ssh = {
          allowedSignersFile = "~/" + homecfg.file.gitAllowedSigners.target;
        };
      };
      rerere = { enabled = true; };
      rebase = { updateRefs = true; };

      credential = {} // 
        lib.optionalAttrs ghcfg.enable {
          "https://github.com" = {
            username = ghcfg.username;
          };
        } // 
        lib.optionalAttrs glcfg.enable {
          "https://gitlab.com" = {
            username = glcfg.username;
          };
        };
    };

    includes = [
    ]
    ++ lib.lists.optionals (ghcfg.enable && 
        builtins.stringLength ghcfg.noreply_email > 0 &&
        ghcfg.noreply_email != config.programs.git.userEmail)
    [
      #### The following specify noreply email for github repos
      {
        condition = "hasconfig:remote.*.url:git@github.com:*/**";
        contents = {
          user = { email = ghcfg.noreply_email; };
        };
      }
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        contents = {
          user = { email = ghcfg.noreply_email; };
        };
      }
      {
        condition = "hasconfig:remote.*.url:https://*@github.com/**";
        contents = {
          user = { email = ghcfg.noreply_email; };
        };
      }
    ]
    ++ lib.lists.optionals (glcfg.enable && 
        builtins.stringLength glcfg.noreply_email > 0 &&
        glcfg.noreply_email != config.programs.git.userEmail)
    [
      #### The following specify noreply email for gitlab repos
      {
        condition = "hasconfig:remote.*.url:git@gitlab.com:*/**";
        contents = {
          user = { email = glcfg.noreply_email; };
        };
      }
      {
        condition = "hasconfig:remote.*.url:https://gitlab.com/**";
        contents = {
          user = { email = glcfg.noreply_email; };
        };
      }
      {
        condition = "hasconfig:remote.*.url:https://*@gitlab.com/**";
        contents = {
          user = { email = glcfg.noreply_email; };
        };
      }
    ];

    lfs = { enable = true; };
    ##### THE FOLLOWING IS GENERATED BY lfs.enable = true
    # [filter "lfs"]
    #    clean = "git-lfs clean -- %f"
    #    process = "git-lfs filter-process"
    #    smudge = "git-lfs smudge -- %f"
    #    required = true

    signing = {
      format = "ssh";
      key = if onepasscfg.sshsign_pgm_present then sshcfg.userssh_pubkey else sshcfg.nixidssh_pubkey;
      signByDefault = true;
    } // lib.optionalAttrs onepasscfg.sshsign_pgm_present {
      signer = onepasscfg.SSHSIGN_PROGRAM;
    };

  };

  programs.kitty = {
    enable = true;
    package = lib.mkIf (nixAppInstalled "kitty") null;
    font = {
      name = "FiraMono Nerd Font Mono";
      size = 18;
    };
    keybindings = {
      # Space added in front of --new-mode to ensure that it appears before --mode keys
      #  in kitty.conf
      " --new-mode pfx" = "--on-action end --on-unknown end ctrl+a";
      "--mode pfx ctrl+a" = "send_key ctrl+a";
      "--mode pfx shift+r" = "load_config_file";
      "--mode pfx h" = "launch --location=hsplit --cwd=current";
      "--mode pfx v" = "launch --location=vsplit --cwd=current";
      "--mode pfx c" = "new_tab";
      "--mode pfx n" = "next_tab";
      "--mode pfx p" = "previous_tab";
      "--mode pfx 1" = "goto_tab 1";
      "--mode pfx 2" = "goto_tab 2";
      "--mode pfx 3" = "goto_tab 3";
      "--mode pfx 4" = "goto_tab 4";
      "--mode pfx 5" = "goto_tab 5";
      "--mode pfx 6" = "goto_tab 6";
      "--mode pfx 7" = "goto_tab 7";
      "--mode pfx 8" = "goto_tab 8";
      "--mode pfx 9" = "goto_tab 9";
      "--mode pfx apostrophe" = "select_tab";

      "--mode pfx :" = "kitty_shell";
      "--mode pfx !" = "detach_window new-tab";
      "--mode pfx @" = "detach_window ask";
      "--mode pfx q" = "focus_visible_window";

      # Select layout
      "--mode pfx alt+1" = "goto_layout splits";
      "--mode pfx alt+2" = "goto_layout horizontal";
      "--mode pfx alt+3" = "goto_layout vertical";
      "--mode pfx alt+4" = "goto_layout fat";
      "--mode pfx alt+5" = "goto_layout tall";
      "--mode pfx alt+6" = "goto_layout grid";

      # TMUX-like copy mode - access the scrollback pager
      "--mode pfx [" = "show_scrollback";

      "--mode pfx ?" = "debug_config";

      "--mode pfx esc" = "pop_keyboard_mode";

      "ctrl+h" = "neighboring_window left";
      "ctrl+l" = "neighboring_window right";
      "ctrl+k" = "neighboring_window top";
      "ctrl+j" = "neighboring_window bottom";
    };
    settings = {
      bold_font = "auto";
      italic_font  = "auto";
      bold_italic_font  = "auto";
      inactive_text_alpha = 0.5;
      background_opacity = 0.85;
      background_blur = 20;
      dynamic_background_opacity = true;
      background_image_layout = "cscaled";
      background_image = "./totoro-dimmed.jpeg";
      # Setup in a similar fashion as tmux
      enabled_layouts = "splits,horizontal,vertical,fat,tall,grid";

      macos_quit_when_last_window_closed = true;

      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "round";
      tab_bar_min_tabs = 1;
      tab_title_template = "\"{fmt.fg.red}{keyboard_mode}{bell_symbol}{activity_symbol} {fmt.fg.tab}{title} | {fmt.fg.yellow}{index}\"";
      active_tab_title_template = "\"{fmt.fg.red}{keyboard_mode}{bell_symbol}{activity_symbol} {fmt.fg.tab}{title} | {layout_name} | {fmt.fg.yellow}{index}\"";

      startup_session = "startup.conf";
    };
    shellIntegration = {
      enableZshIntegration = true;
    };
    themeFile = "Catppuccin-Mocha";
  };

  ### Setup the user-specific launch agents
  launchd.agents.activate-agenix.config.ProcessType = lib.mkForce "Standard";
  launchd.enable = true;
  launchd.agents = {
    detectNixUpdates = {
      enable = true;
      config = {
        Label = "org.nixos.detectNixUpdates";
        ProgramArguments = [
          "${pkgs.bashInteractive}/bin/bash"
          "-l"
          "-c"
          ("
          LASTUPDATENIXPKGS=\$(cat ~/log/detectNixUpdates.log 2>/dev/null)
          UPDATENIXPKGS=\$(~/.config/nixpkgs/launchdagents/checkNixpkgs.sh 2>&1 1>/dev/null)
          if [ -n \"$UPDATENIXPKGS\" ] && [ \"$UPDATENIXPKGS\" != \"$LASTUPDATENIXPKGS\" ]; then
            osascript -e \"display notification \\\"\${UPDATENIXPKGS}\\\" with title \\\"New nix channel updates\\\"\"

            # COMMENTED OUT OPTION TO SEND MESSAGE VIA EMAIL
            # osascript -e \"
            #   set emailSubject to \\\"New nix channel updates\\\"
            #   set emailBody to \\\"\${UPDATENIXPKGS}\\\"
            #   tell application \\\"Mail\\\"
            #     set newMessage to make new outgoing message with properties {subject:emailSubject, content:emailBody, visible:false}
            #     tell newMessage
            #       make new to recipient with properties {address:$IMSGID}
            #     end tell
            #
            #     send newMessage
            #   end tell
            # \"
          " + lib.optionalString (osConfig.machineInfo.hostname == "MacBook-Pro") "
            IMSGID=\$(jq '.iMessageID' ${config.age.secrets."armored-secrets.json".path} 2>/dev/null)
            if [ -n \"$IMSGID\" ]; then
              osascript -e \"tell application \\\"Messages\\\" to send \\\"\${UPDATENIXPKGS}\\\" to buddy $IMSGID\"
            fi
          " + "
          fi
          echo \"$UPDATENIXPKGS\" > ~/log/detectNixUpdates.log
          ")
          ];
        RunAtLoad = true;
        StartInterval = 60*20;
        StandardOutputPath = "${homecfg.homeDirectory}/log/org.nixos.detectNixUpdates-output.log";
        StandardErrorPath = "${homecfg.homeDirectory}/log/org.nixos.detectNixUpdates-error.log";
      };
    };
    LoginStartTerminal = {
      enable = true;
      config = {
        Label = "org.nixos.user.LoginStartTerminal";
        ProgramArguments = [
          "osascript"
          "-e" "
          try
            tell application \"/Applications/Nix Apps/kitty.app\" to activate
          on error errMsg number errNumber
            log \"Error (\" & errNumber & \"): \" & errMsg
            tell application \"Terminal\"
              if not (exists window 1) then reopen
              activate
              set winID to id of window 1
              do script \"tmux 2>/dev/null\" in window id winID
            end tell
          end try
          "
          ];
        RunAtLoad = true;
        StandardOutputPath = "${homecfg.homeDirectory}/log/org.nixos.user.loginterm.log";
        StandardErrorPath = "${homecfg.homeDirectory}/log/org.nixos.user.logintermError.log";
      };
    };
    # LoginStartTmux = {
    #   enable = true;
    #   config = {
    #     Label = "org.nixos.user.LoginStartTmux";
    #     ProgramArguments = [
    #       "osascript"
    #       "-e" "
    #       tell application \"Terminal\"
    #         if not (exists window 1) then reopen
    #         activate
    #         set winID to id of window 1
    #         do script \"tmux 2>/dev/null\" in window id winID
    #       end tell
    #       return
    #       "
    #       ];
    #     RunAtLoad = true;
    #   };
    # };
    updateTmuxPlugins = {
      enable = true;
      config = {
        Label = "org.nixos.user.updateTmuxPlugins";
        ProgramArguments = [
          "${pkgs.bashInteractive}/bin/bash"
          "-l"
          "-c"
          "
          >&2 date
          [ -d ${homecfg.homeDirectory}/.tmux/plugins/tpm ] || ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm.git ${homecfg.homeDirectory}/.tmux/plugins/tpm
           >&2 ${pkgs.tmux}/bin/tmux -c \"${homecfg.homeDirectory}/.tmux/plugins/tpm/bin/install_plugins\"
           >&2 ${pkgs.tmux}/bin/tmux -c \"${homecfg.homeDirectory}/.tmux/plugins/tpm/bin/update_plugins all\"
           >&2 ${pkgs.tmux}/bin/tmux -c \"${homecfg.homeDirectory}/.tmux/plugins/tpm/bin/clean_plugins\"
           >&2 echo \"Completed TPM plugin updates\"
          "];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${homecfg.homeDirectory}/log/org.nixos.user.tmuxupdate.log";
        StandardErrorPath = "${homecfg.homeDirectory}/log/org.nixos.user.tmuxupdateError.log";
      };
    };
    updateNvimPlugins = {
      enable = true;
      config = {
        Label = "org.nixos.user.updateNvimPlugins";
        ProgramArguments = [
          "${pkgs.bashInteractive}/bin/bash"
          "-l"
          "-c"
          "
          >&2 date
          ${pkgs.neovim}/bin/nvim --headless \"+Lazy! sync\" \"+MasonUpdate\" \"+MasonToolsUpdateSync\" \"+qa\" 
          >&2 echo \"\"
          "
          ];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${homecfg.homeDirectory}/log/org.nixos.user.nvimupdate.log";
        StandardErrorPath = "${homecfg.homeDirectory}/log/org.nixos.user.nvimupdateError.log";
      };
    };
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "26.05";
}

