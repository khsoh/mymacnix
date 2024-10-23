{ config, osConfig, pkgs, lib, ... }:
let
  homecfg = config.home;
  onepasscfg = config.onepassword;
  sshcfg = config.sshkeys;
  ghcfg = config.github;
  glcfg = config.gitlab;

  ## Default git email - will be available to public
  default_git_email = "hju37823@outlook.com";

  NIXSYSPATH = "/run/current-system/sw/bin";

in {
  imports = [
    ./usermod
  ];

  ## User-specific aliases
  home.shellAliases = {
    cdnix = "cd ~/github/mymacnix/dot-config/nixpkgs/darwin";
  };

  home.file.resize_app = {
    ## AppleScript file to resize app
    target = ".config/scpt/resize_app.scpt";
    source = ./scpt/resize_app.scpt;
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

    target = ".config/tmux";
    #source = ../tmux;
    source = pkgs.fetchFromGitHub {
      owner = ghcfg.username;
      repo = "tmuxconf";
      rev="b83d4c2d9535076c8dea0579bf9c2ed69016a1ab";
      sha256="sha256-OU5Vypf80a0ncMBS/d7THqBtM76bN091ND8GZDZ81z0=";
      #sha256 = lib.fakeSha256;
    };
    recursive = true;
  };

  home.file.kitty = {
    ## The defaults are commented out
    # enable = true;

    target = ".config/kitty";
    #source = ../kitty;
    source = pkgs.fetchFromGitHub {
      owner = ghcfg.username;
      repo = "kittyconf";
      rev="beeb983c2c8b117e75af536b94f26077cc03937e";
      sha256="sha256-Sv32mCgU7ibsbT0tG4cl+4l7uqHovJwT0nLhrjc4Mvg=";
      #sha256 = lib.fakeSha256;
    };
    recursive = true;
  };

  home.file.nvim = {
    ## The defaults are commented out
    # enable = true;

    target = ".config/nvim";
    #source = ../nvim;
    source = pkgs.fetchFromGitHub {
      owner = ghcfg.username;
      repo = "kickstart.nvim";
      rev="49b5805e59204d22229492f64c2fc7e7964c6156";
      sha256="sha256-816Jwu7CqkVMJJLj9zdrUa1Rh/NMrfGpoPHGH4toD7A=";
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
      XDG_CONFIG_HOME = "\${XDG_CONFIG_HOME:-$HOME/.config}";
      XDG_DATA_HOME = "\${XDG_DATA_HOME:-$HOME/.local/share}";
      EDITOR = "vim";
    };  # Written to start of .profile

    # Written to end of .profile
    profileExtra = builtins.readFile ./bash/profile-extra;
  };

  ### Enable zsh configuration
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    autocd = true;
    defaultKeymap = "viins";
    completionInit = "";
    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      TERMINFO_DIRS = "\${TERMINFO_DIRS:-/usr/share/terminfo}:$HOME/.local/share/terminfo";
      XDG_CONFIG_HOME = "\${XDG_CONFIG_HOME:-$HOME/.config}";
      XDG_DATA_HOME = "\${XDG_DATA_HOME:-$HOME/.local/share}";
      EDITOR = "vim";
    };

    profileExtra = builtins.readFile ./zsh/zprofile-extra;
    initExtra = builtins.readFile ./zsh/zshrc-initExtra;
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
      addKeysToAgent = "no";
      extraConfig = ''
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      '';
    } else {
      enable = true;
      addKeysToAgent = "yes";
      extraConfig = ''
        IdentityFile ${sshcfg.NIXIDPKFILE};
      '';
    };

  ### Enable git configuration
  programs.git = {
    enable = true;
    userName = "K H Soh";
    userEmail = default_git_email;

    aliases = {
      co = "checkout";
      ci = "commit";
      br = "branch";
      st = "status";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      glog = "log --graph --all";
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

    extraConfig = {
      ### The following are needed because home-manager's gpg/signing module
      #  does not support ssh
      user = { signingkey = if onepasscfg.sshsign_pgm_present then sshcfg.userssh_pubkey else sshcfg.nixidssh_pubkey; };
      gpg = {
        format = "ssh";
        ssh = {
          allowedSignersFile = "~/" + homecfg.file.gitAllowedSigners.target;
        } // lib.optionalAttrs onepasscfg.sshsign_pgm_present {
            program = onepasscfg.SSHSIGN_PROGRAM;
          };
      };
      commit = { gpgsign = true; };
      tag = { gpgsign = true; };

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

  };

  ### Setup the user-specific launch agents
  launchd.enable = true;
  launchd.agents = {
    checkNixpkgs = {
      enable = true;
      config = {
        Label = "checkNixpkgs";
        ProgramArguments = [
          "${pkgs.bashInteractive}/bin/bash"
          "-l"
          "-c"
          "
          NIXDARWIN_VERSION=\$(${NIXSYSPATH}/darwin-version --darwin-label)
          REMOTE_VERSION=\$(NIX_PATH=nixpkgs=channel:nixpkgs-unstable ${pkgs.nix}/bin/nix-instantiate --eval --expr \"(import &lt;nixpkgs&gt; {}).lib.version\"|${pkgs.gnused}/bin/sed -e 's/\"//g')
          LOCAL_VERSION=\${NIXDARWIN_VERSION%%+?*}
          LAST_REMOTE_VERSION=\$(/usr/bin/grep \"^REMOTE_VERSION::\\s\\+\" ~/log/checknixpkgsError.log | tail -1 | ${pkgs.gnused}/bin/sed -n -e 's/^REMOTE_VERSION::\\s\\+//p')

          &gt;&amp;2 echo \"\"
          &gt;&amp;2 date
          if [[ \"$LOCAL_VERSION\" != \"$REMOTE_VERSION\" ]]; then
            &gt;&amp;2 echo \"***New nixpkgs version detected for update on nixpkgs-unstable channel\"
            &gt;&amp;2 echo \"  LOCAL_VERSION::  $LOCAL_VERSION\"
            &gt;&amp;2 echo \"  REMOTE_VERSION:: $REMOTE_VERSION\"
            if [[ \"$REMOTE_VERSION\" != \"$LAST_REMOTE_VERSION\" ]]; then
              osascript -e \"display notification \\\"Local::  $LOCAL_VERSION\\nRemote:: $REMOTE_VERSION\\\" with title \\\"New nixpkgs version detected on nixpkgs-unstable channel\\\"\"
            fi
          else
            &gt;&amp;2 echo \"Local nixpkgs version is up-to-date with nixpkgs-unstable channel\"
            &gt;&amp;2 echo \"  LOCAL_VERSION::  $LOCAL_VERSION\"
          fi
          "
          ];
        RunAtLoad = true;
        StartInterval = 3600;
        StandardOutputPath = "${homecfg.homeDirectory}/log/checknixpkgsOutput.log";
        StandardErrorPath = "${homecfg.homeDirectory}/log/checknixpkgsError.log";
      };
    };
    checkNixchannels = {
      enable = true;
      config = {
        Label = "checkNixchannels";
        ProgramArguments = [
          "${pkgs.bashInteractive}/bin/bash"
          "-l"
          "-c"
          "
          declare -A NIXCHANNELS

          eval \"\$(nix-channel --list|awk 'BEGIN { OFS=\"\" } { print \"NIXCHANNELS[\",$1,\"]=\",$2 }')\"

          &gt;&amp;2 echo \"\"
          &gt;&amp;2 date
          for pkg in \"\${!NIXCHANNELS[@]}\"; do
              pkgpath=\$(/usr/bin/readlink -f \$(${pkgs.nix}/bin/nix-instantiate --eval --expr \"&lt;\${pkg}&gt;\"))
              if [[ ! -z \${pkgpath+x} ]]; then
                  pkgurl=\${NIXCHANNELS[$pkg]}

                  lastrhash=\$(/usr/bin/grep \"^\${pkg}_remote_hash:\\s\\+\" ~/log/checknixchannelsError.log | tail -1 | ${pkgs.gnused}/bin/sed -n -e 's/^\${pkg}_remote_hash:\\s\\+//p')
                  lhash=\$(nix-hash --base32 --type sha256 $pkgpath/)
                  rhash=\$(nix-prefetch-url --unpack --type sha256 $pkgurl 2&gt; /dev/null)

                  if [[ \"$lhash\" != \"$rhash\" ]]; then
                    &gt;&amp;2 echo \"***New package detected for update on $pkg channel:\"
                    &gt;&amp;2 echo \"  \${pkg}_local_hash:  $lhash\"
                    &gt;&amp;2 echo \"  \${pkg}_remote_hash: $rhash\"
                    if [[ \"$rhash\" != \"$lastrhash\" ]]; then
                      osascript -e \"display notification \\\"\${pkg}_local_hash:  $lhash\\n\${pkg}_remote_hash: $rhash\\\" with title \\\"New package detected for update on $pkg channel\\\"\"
                    fi
                  else
                    &gt;&amp;2 echo \"Local package is up-to-date with $pkg channel\"
                    &gt;&amp;2 echo \"  \${pkg}_local_hash:  $lhash\"
                  fi
              else
                &gt;&amp;2 echo \"!!!Cannot find local installed package detected for channel $pkg\"
                osascript -e \"display notification \\\"Cannot find local installed package for channel $pkg\\\" with title \\\"Channel $pkg error\\\"\"
              fi
          done
          "
          ];
        RunAtLoad = true;
        StartInterval = 3600;
        StandardOutputPath = "${homecfg.homeDirectory}/log/checknixchannelsOutput.log";
        StandardErrorPath = "${homecfg.homeDirectory}/log/checknixchannelsError.log";
      };
    };
    LoginStartTerminal = {
      enable = true;
      config = {
        Label = "LoginStartTerminal";
        ProgramArguments = [
          "osascript"
          "-e" "
          try
            tell application \"kitty\" to activate
            delay 2
            run script \"${homecfg.homeDirectory}/.config/scpt/resize_app.scpt\" with parameters { \".kitty-wrapped\" }
          on error errMsg
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
        StandardOutputPath = "${homecfg.homeDirectory}/log/loginterm.log";
        StandardErrorPath = "${homecfg.homeDirectory}/log/logintermError.log";
      };
    };
    # LoginStartTmux = {
    #   enable = true;
    #   config = {
    #     Label = "LoginStartTmux";
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
        Label = "updateTmuxPlugins";
        ProgramArguments = [
          "${pkgs.bashInteractive}/bin/bash"
          "-l"
          "-c"
          "
          &gt;&amp;2 date
          [ -d ${homecfg.homeDirectory}/.tmux/plugins/tpm ] || ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm.git ${homecfg.homeDirectory}/.tmux/plugins/tpm
           &gt;&amp;2 ${pkgs.tmux}/bin/tmux -c \"${homecfg.homeDirectory}/.tmux/plugins/tpm/bin/install_plugins\"
           &gt;&amp;2 ${pkgs.tmux}/bin/tmux -c \"${homecfg.homeDirectory}/.tmux/plugins/tpm/bin/update_plugins all\"
           &gt;&amp;2 ${pkgs.tmux}/bin/tmux -c \"${homecfg.homeDirectory}/.tmux/plugins/tpm/bin/clean_plugins\"
           &gt;&amp;2 echo \"Completed TPM plugin updates\"
          "];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${homecfg.homeDirectory}/log/tmuxupdate.log";
        StandardErrorPath = "${homecfg.homeDirectory}/log/tmuxupdateError.log";
      };
    };
    updateNvimPlugins = {
      enable = true;
      config = {
        Label = "updateNvimPlugins";
        ProgramArguments = [
          "${pkgs.bashInteractive}/bin/bash"
          "-l"
          "-c"
          "
          &gt;&amp;2 date
          ${pkgs.neovim}/bin/nvim --headless \"+Lazy! sync\" \"+MasonUpdate\" \"+MasonToolsUpdateSync\" \"+qa\" 
          &gt;&amp;2 echo \"\"
          "
          ];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${homecfg.homeDirectory}/log/nvimupdate.log";
        StandardErrorPath = "${homecfg.homeDirectory}/log/nvimupdateError.log";
      };
    };
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

