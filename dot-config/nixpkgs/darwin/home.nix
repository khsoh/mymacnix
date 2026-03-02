{
  config,
  osConfig,
  pkgs,
  lib,
  user,
  ...
}:
let
  homecfg = config.home;
  onepasscfg = config.onepassword;
  sshcfg = config.sshkeys;
  ghcfg = config.github;
  glcfg = config.gitlab;
  termcfg = config.terminal;

  ## Default git email - will be available to public
  default_git_email = "hju37823@outlook.com";

  onepassword_enable = config.onepassword.enable;
  OPCLI = "${pkgs._1password-cli}/bin/op";
  OPSSHSOCK = "${homecfg.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  SSHSOCK =
    if onepassword_enable then
      "${homecfg.homeDirectory}/.1password/agent.sock"
    else
      "${homecfg.homeDirectory}/.ssh/ssh-agent.sock";

  backdropImgPath = "~/" + "${homecfg.file.termBackdrop.target}";

  ## Function to extract first 2 elements of the public key file
  readPubkey =
    pubkeyfile:
    let
      # Read the file and strip the trailing newline
      content = lib.removeSuffix "\n" (builtins.readFile pubkeyfile);
      # Split by spaces into a list of strings
      parts = lib.splitString " " content;
    in
    # Take the first two elements and join them with a space
    builtins.concatStringsSep " " (lib.take 2 parts);

  nonNIXIDsshcfg = removeAttrs sshcfg [ "NIXID" ];

  hasTermPackages = (builtins.length termcfg.packages) > 0;
  hasTermKitty = (builtins.elem pkgs.kitty termcfg.packages);
  hasTermGhostty = (builtins.elem pkgs.ghostty-bin termcfg.packages);
  TERMPROG =
    if hasTermPackages then
      Helpers.getMacBundleAppName (builtins.head termcfg.packages)
    else
      "Terminal.app";

  # Shortcut to get helper functions
  Helpers = osConfig.helpers;
in
{
  imports = [
    <agenix/modules/age-home.nix>
    ./usermod
  ];

  ##### xdg configuration
  xdg.enable = true;

  ##### agenix configuration
  age.identityPaths = lib.mapAttrsToList (name: value: "${value.PKFILE}") sshcfg;

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

  services.ssh-agent = lib.mkIf (!onepassword_enable) {
    enable = true;
  };

  ## User-specific aliases
  home.shellAliases = {
    cdnix = "cd $(readlink -f ${toString ./.})";
    dru = "\"${toString ./.}/../../../darwinupdate\"";
    hbb = "brew bundle";
    hbu = "brew update";
  };

  home.file = lib.mkMerge [
    (lib.mkIf onepassword_enable (
      lib.mapAttrs' (
        name: value:
        lib.nameValuePair "${value.PKFILE}" {
          target = "${value.PKFILE}.tpl";
          text = ''
            {{ ${value.OPURI}/private key?ssh-format=openssh }}
          '';
        }
      ) sshcfg
    ))

    {
      resize_app = {
        ## AppleScript file to resize app
        target = "${config.xdg.configHome}/jxa/resize_app.js";
        source = ./jxa/resize_app.js;
      };

      waitapp = {
        ## JavaScript (JXA) file to wait for DisplayLink Manager to start
        target = "${config.xdg.configHome}/jxa/waitapp.js";
        source = ./jxa/waitapp.js;
      };

      # setting up neovide to use neovim binary
      ".config/neovide/config.toml".text = ''
        # Ensure Neovide uses the exact Neovim binary from your Nix store
        neovim-bin = "${pkgs.neovim}/bin/nvim"
      '';

      ## Generate list of public keys file in pubkeys.nix
      "pubkeys.nix" = {
        ## The defaults are commented out
        # enable = true;

        target = ".config/nixpkgs/secrets/pubkeys.nix";
        text =
          let
            content = lib.strings.concatMapStringsSep "\n  " (k: "\"${k}\"") (
              lib.mapAttrsToList (name: value: readPubkey "${value.PUBFILE}") sshcfg
            );
          in
          ''
            [
              ${content}
            ]
          '';
      };

      gitAllowedSigners = {
        ## Generate the allowed signers file
        # enable = true;

        target = ".ssh/allowed_signers";
        text =
          let
            content = lib.strings.concatMapStringsSep "\n" (k: "${default_git_email} namespaces=\"git\" ${k}") (
              lib.mapAttrsToList (name: value: readPubkey "${value.PUBFILE}") sshcfg
            );
          in
          "${content}\n";
      };

      tmux = {
        ## The defaults are commented out
        # enable = true;

        target = "${config.xdg.configHome}/tmux";
        #source = ../tmux;
        source = pkgs.fetchFromGitHub {
          owner = ghcfg.username;
          repo = "tmuxconf";
          rev = "cd93e8f43024f2527fd673f8397c99bd69497604";
          sha256 = "sha256-QcOi0RlC4wP23Xfx17K/SIx2QlBgA9jwMnryroDSFCE=";
          #sha256 = lib.fakeSha256;
        };
        recursive = true;
      };

      # home.file.kitty = {
      #   ## The defaults are commented out
      #
      #   # Enable kitty config if kitty is installed in Nix or homebrew
      #   enable = Helpers.pkgInstalled pkgs.kitty || Helpers.brewAppInstalled "kitty";
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
      kittyStartup = lib.mkIf (hasTermKitty || Helpers.brewAppInstalled "kitty") {
        # Enable kitty config if kitty is installed in Nix or homebrew
        enable = true;

        target = "${config.xdg.configHome}/kitty/startup.conf";
        text = ''
          cd ~/github
          layout splits
          launch zsh
          launch --location hsplit zsh
          launch --type overlay zsh -c "${config.xdg.configHome}/jxa/waitapp.js 'DisplayLink Manager.app' && date > ~/log/kittyStart.log && sleep 2 && ${config.xdg.configHome}/jxa/resize_app.js kitty >>& ~/log/kittyStart.log"
        '';
      };
      termBackdrop = lib.mkIf (hasTermPackages || Helpers.brewAppInstalled "kitty") {
        # Enable image backdrop for terminals if kitty or ghostty is installed in Nix or homebrew
        enable = true;
        target = "${config.xdg.configHome}/backdrop/totoro-dimmed.jpeg";
        source = ./images/totoro-dimmed.jpeg;
      };
      kitty_tabbar_py = lib.mkIf (hasTermKitty || Helpers.brewAppInstalled "kitty") {
        # Enable kitty tab bar if kitty is installed in Nix or homebrew
        enable = true;
        target = "${config.xdg.configHome}/kitty/tab_bar.py";
        source = ./kitty/tab_bar.py;
      };

      nvim = {
        ## The defaults are commented out
        # enable = true;

        target = "${config.xdg.configHome}/nvim";
        source = pkgs.fetchFromGitHub {
          owner = ghcfg.username;
          repo = "kickstart.nvim";
          rev = "57a559d57a32c2ccd98053004c5830e85b1b0793";
          sha256 = "sha256-wSgCvmyUQ3gIuIaWZwEhccklm9VRRpGRYGyLf2IW7rU=";
          #sha256 = lib.fakeSha256;
        };
        recursive = true;
      };

      ## Need to specify the symbolic link in this manne because the secret is generated at runtime and
      #  does not exist in Nix store.
      "Dygma/Dygma-mac-raise2.json".source =
        config.lib.file.mkOutOfStoreSymlink "${osConfig.services.onepassword-secrets.outputDir}/dygmaMacRaise2.json";
    }
  ];

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
    }
    // lib.optionalAttrs onepassword_enable {
      SSH_AUTH_SOCK = "${SSHSOCK}";
    }; # Written to start of .profile

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
    }
    // lib.optionalAttrs onepassword_enable {
      SSH_AUTH_SOCK = "${SSHSOCK}";
    }; # Written to start of .profile

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
  programs.ssh = lib.mkMerge [
    (lib.mkIf onepassword_enable {
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
        IdentityAgent "${SSHSOCK}"
      '';
    })

    (lib.mkIf (!onepassword_enable) {
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
        IdentityFile ${sshcfg.NIXID.PKFILE}
      '';
    })
  ];

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
      rerere = {
        enabled = true;
      };
      rebase = {
        updateRefs = true;
      };

      credential =
        { }
        // lib.optionalAttrs ghcfg.enable {
          "https://github.com" = {
            username = ghcfg.username;
          };
        }
        // lib.optionalAttrs glcfg.enable {
          "https://gitlab.com" = {
            username = glcfg.username;
          };
        };
    };

    includes = [
    ]
    ++
      lib.lists.optionals
        (
          ghcfg.enable
          && builtins.stringLength ghcfg.noreply_email > 0
          && ghcfg.noreply_email != config.programs.git.userEmail
        )
        [
          #### The following specify noreply email for github repos
          {
            condition = "hasconfig:remote.*.url:git@github.com:*/**";
            contents = {
              user = {
                email = ghcfg.noreply_email;
              };
            };
          }
          {
            condition = "hasconfig:remote.*.url:https://github.com/**";
            contents = {
              user = {
                email = ghcfg.noreply_email;
              };
            };
          }
          {
            condition = "hasconfig:remote.*.url:https://*@github.com/**";
            contents = {
              user = {
                email = ghcfg.noreply_email;
              };
            };
          }
        ]
    ++
      lib.lists.optionals
        (
          glcfg.enable
          && builtins.stringLength glcfg.noreply_email > 0
          && glcfg.noreply_email != config.programs.git.userEmail
        )
        [
          #### The following specify noreply email for gitlab repos
          {
            condition = "hasconfig:remote.*.url:git@gitlab.com:*/**";
            contents = {
              user = {
                email = glcfg.noreply_email;
              };
            };
          }
          {
            condition = "hasconfig:remote.*.url:https://gitlab.com/**";
            contents = {
              user = {
                email = glcfg.noreply_email;
              };
            };
          }
          {
            condition = "hasconfig:remote.*.url:https://*@gitlab.com/**";
            contents = {
              user = {
                email = glcfg.noreply_email;
              };
            };
          }
        ];

    lfs = {
      enable = true;
    };
    ##### THE FOLLOWING IS GENERATED BY lfs.enable = true
    # [filter "lfs"]
    #    clean = "git-lfs clean -- %f"
    #    process = "git-lfs filter-process"
    #    smudge = "git-lfs smudge -- %f"
    #    required = true

    signing = {
      format = "ssh";
      #key = if userssh_pubkey != null then userssh_pubkey else nixidssh_pubkey;
      key =
        if builtins.attrNames nonNIXIDsshcfg != [ ] then
          builtins.head (lib.mapAttrsToList (name: value: readPubkey "${value.PUBFILE}") nonNIXIDsshcfg)
        else
          readPubkey "${sshcfg.NIXID.PUBFILE}";
      signByDefault = true;
    }
    // lib.optionalAttrs onepasscfg.enable {
      signer = onepasscfg.SSHSIGN_PROGRAM;
    };

  };

  programs.kitty = lib.mkIf hasTermKitty {
    enable = true;
    package = if Helpers.pkgInstalled pkgs.kitty then null else pkgs.kitty;
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
      italic_font = "auto";
      bold_italic_font = "auto";
      inactive_text_alpha = 0.5;
      background_opacity = 0.85;
      background_blur = 20;
      dynamic_background_opacity = true;
      background_image_layout = "cscaled";
      background_image = "${backdropImgPath}";
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
    extraConfig = ''
      scrollback_pager sh -c "FILE=$(mktemp /tmp/kitty_scrollback.XXXXXX) && chmod 600 \$FILE && ${pkgs.neovim}/bin/nvim --noplugin -c 'set clipboard=unnamedplus signcolumn=no showtabline=0' -c \"silent write! \$FILE | te cat \$FILE\" -c 'autocmd VimLeave * silent! !rm \$FILE'"
    '';
    shellIntegration = {
      enableZshIntegration = true;
    };
    themeFile = "Catppuccin-Mocha";
  };

  programs.ghostty = lib.mkIf hasTermGhostty {
    # Commented out items are the defaults
    enable = true;
    # enableBashIntegration = homecfg.shell.enableBashIntegration;
    # enableFishIntegration = homecfg.shell.enableFishIntegration;
    # enableZshIntegration = homecfg.shell.enableZshIntegration;
    package = if Helpers.pkgInstalled pkgs.ghostty-bin then null else pkgs.ghostty-bin;
    # clearDefaultKeybinds = false;
    # installBatSyntax = true;
    # installVimSyntax = false;
    settings = {
      initial-command = "${pkgs.zsh}/bin/zsh -c '${config.xdg.configHome}/jxa/waitapp.js \"DisplayLink Manager.app\" && date > ~/log/ghosttyStart.log && sleep 2 && ${config.xdg.configHome}/jxa/resize_app.js ghostty >>& ~/log/ghosttyStart.log; exec ${pkgs.zsh}/bin/zsh'";
      theme = "Catppuccin Mocha";
      font-family = "FiraMono Nerd Font Mono";
      font-size = 18;

      # Match Kitty's standard text brightness
      foreground = "#cdd6f4";

      # Brighten the ANSI "white" colors (index 7 and 15)
      palette = [
        "7=#e0e0e0"
        "15=#ffffff"
      ];

      # Improve text "pop" and thickness
      alpha-blending = "linear-corrected";
      minimum-contrast = 1.1;
      bold-is-bright = true;

      # Font Thickness
      font-thicken = true;
      font-thicken-strength = 120; # 0-255; higher is thicker

      ## Glassy minimalist
      # macos-titlebar-style = "hidden";
      # background-opacity = 0.85;
      # background-blur-radius = 20;
      # window-padding-x = 15;
      # window-padding-y = 15;
      # window-decoration = false;

      ## Safari Style (Integrated Tabs)
      # macos-titlebar-style = "tabs";
      # window-padding-balance = true;
      # macos-titlebar-proxy-icon = "hidden";
      # window-padding-x = 10;

      ## Transparent Float (Buttons only)
      macos-titlebar-style = "transparent";
      background-opacity = 0.9;
      window-padding-y = 10;
      split-divider-color = "#cba6f7";
      unfocused-split-opacity = 0.6;
      unfocused-split-fill = "#181825";

      background-image = "${config.xdg.configHome}/backdrop/totoro-dimmed.jpeg";
      background-image-opacity = 1.0;
      #background-image-fit = "contain";

      auto-update = "off";
      keybind = [
        # Map Cmd+Shift+J to open the scrollback in Neovide (via macOS default)
        "cmd+shift+j=write_scrollback_file:open"

        # Optional: Map Cmd+Shift+K to open ONLY the current visible screen
        "cmd+shift+k=write_screen_file:open"

        "ctrl+a>h=new_split:down"
        "ctrl+a>v=new_split:right"
        "ctrl+h=goto_split:left"
        "ctrl+j=goto_split:bottom"
        "ctrl+k=goto_split:top"
        "ctrl+l=goto_split:right"
        "ctrl+a>c=new_tab"
        "ctrl+a>n=next_tab"
        "ctrl+a>p=previous_tab"

        # goto tab N
        "ctrl+a>1=goto_tab:1"
        "ctrl+a>2=goto_tab:2"
        "ctrl+a>3=goto_tab:3"
        "ctrl+a>4=goto_tab:4"
        "ctrl+a>5=goto_tab:5"
        "ctrl+a>6=goto_tab:6"
        "ctrl+a>7=goto_tab:7"
        "ctrl+a>8=goto_tab:8"
        "ctrl+a>9=goto_tab:9"
      ];
    };
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
          (
            ''
              LASTUPDATENIXPKGS=$(cat ~/log/detectNixUpdates.log 2>/dev/null)
              UPDATENIXPKGS=$(~/.config/nixpkgs/launchdagents/checkNixpkgs.sh 2>&1 1>/dev/null)
              LOCALHOSTNAME=$(/usr/sbin/scutil --get LocalHostName)
              if [ -n "$UPDATENIXPKGS" ] && [ "$UPDATENIXPKGS" != "$LASTUPDATENIXPKGS" ]; then
                export UPDATENIXPKGS
                osascript -l JavaScript <<EOF
                  var app = Application.currentApplication();
                  app.includeStandardAdditions = true;
                  var updateText = ObjC.unwrap($.NSProcessInfo.processInfo.environment.objectForKey('UPDATENIXPKGS'));

                  updateText = updateText ? String(updateText) : "No updates found";

                  app.displayNotification(updateText, { withTitle: 'New nix channel updates' });
              EOF
            ''
            + (lib.optionalString (user.hasAppleID) ''
                IMSGID=$(jq '.iMessageID' ${config.age.secrets."armored-secrets.json".path} 2>/dev/null)
                if [ -n "$IMSGID" ]; then
                  MSGSTR=$(cat <<MYMSG
              $LOCALHOSTNAME nix-channel updates:
              $UPDATENIXPKGS
              MYMSG
              )
                  export MSGSTR
                  osascript -l JavaScript <<EOF1
                    const Messages = Application('Messages');
                    const person = Messages.participants.whose({ handle: $IMSGID });
                    if (person.length > 0) {
                      var updateText = ObjC.unwrap($.NSProcessInfo.processInfo.environment.objectForKey('MSGSTR'));
                      updateText = updateText ? String(updateText) : "No updates found";
                      Messages.send(updateText, { to: person[0] });
                    }
              EOF1
                fi
            '')
            + ''
              fi
              echo "$UPDATENIXPKGS" > ~/log/detectNixUpdates.log
            ''
          )
        ];
        RunAtLoad = true;
        StartInterval = 60 * 20;
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
          "-l"
          "JavaScript"
          "-e"
          ''
            const TERMAPP="${TERMPROG}";
            try {
              // Use the path to target the specific Kitty installation
              if (TERMAPP != "Terminal.app") {
                Application("${TERMPROG}").activate();
              }
            } catch (err) {
              // err contains the message;
              console.log("Error: " + err?.message);

            }
            if (TERMAPP == "Terminal.app" || TERMAPP == "Terminal") {
              const terminal = Application(TERMAPP);

              terminal.activate();

              // Reopen Terminal if no windows exist
              let wins = terminal.windows();
              if (wins.length === 0) {
                terminal.reopen();
                wins = terminal.windows();
              }

              // Execute the command in that specific window
              terminal.doScript("tmux 2>/dev/null", { in: wins[0] });
            }
          ''
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
          "
        ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
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
        KeepAlive = {
          SuccessfulExit = false;
        };
        StandardOutputPath = "${homecfg.homeDirectory}/log/org.nixos.user.nvimupdate.log";
        StandardErrorPath = "${homecfg.homeDirectory}/log/org.nixos.user.nvimupdateError.log";
      };
    };
  };

  home.activation = {
    start1Password = lib.mkIf onepassword_enable (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        ''
          RERUN=0
          # 1. Define a 1Password login function
          op_login() {
            if ! ${OPCLI} whoami > /dev/null 2>&1; then
              printf "\033[1;34m1Password is locked. Please authenticate...\033[0m\n"
              # If app integration is on, any command triggers the prompt.
              # We'll use 'signin' to be explicit.
              eval $(${OPCLI} signin)
            fi
          }

          # 2. Define key installation function
          install_keys() {
            PKFILE=$1
            PUBFILE=$2
            OPURI=$3
            remote_fp=$(/bin/cat "''${PKFILE}.fp" 2>/dev/null || ${OPCLI} read "''${OPURI}/fingerprint")
            if [ ! -f "$PKFILE" ] ||
              [ "$(${pkgs.openssh}/bin/ssh-keygen -lf "$PKFILE" | /usr/bin/awk '{print $2}')" != "$remote_fp" ]; then
              RERUN=1
              printf "\033[1;34mMissing %s file - extracting it from 1Password\033[0m\n" "$PKFILE"
              ${OPCLI} inject -i "''${PKFILE}.tpl" -o "$PKFILE" --force
            fi
            if [ ! -f "$PUBFILE" ]; then
              RERUN=1
              printf "\033[1;34mMissing %s file - re-generating it from the private key\033[0m\n" "$PUBFILE"
              ${pkgs.openssh}/bin/ssh-keygen -y -f "$PKFILE" > "$PUBFILE"
            fi
            ${pkgs.openssh}/bin/ssh-keygen -lf "$PKFILE" | /usr/bin/awk '{print $2}' > "''${PKFILE}.fp"
          }

          # 2. Create the .1password directory if it does not exist
          /bin/mkdir -p "$(dirname "${SSHSOCK}")"

          # 3. Symlink the 1Password-managed socket to the standard location
          # Replace the source path if 1Password changes it, but this is the current macOS default
          /bin/ln -sfn "${OPSSHSOCK}" "${SSHSOCK}"

          # 4. Check that 1Password is running
          if ! /usr/bin/pgrep -x "1Password" > /dev/null; then
            printf "\n\033[1;34m--- Executing 1Password ---\033[0m\n"
            /usr/bin/open -a "1Password" --args --silent
            /bin/sleep 2

            # 5. Ensure at least one account is configured on this machine
            if ! ${OPCLI} account list > /dev/null 2>&1; then
              printf "\033[1;34mNo 1Password account found. Starting initial setup...\033[0m\n"
              ${OPCLI} account add
            fi

          fi

          # 6. Confirm existence of .ssh directory
          /bin/mkdir -p $HOME/.ssh && /bin/chmod 700 $HOME/.ssh

        ''
        + lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: value: ''
            # Generate the keys if their fingerprint differ
            install_keys "${value.PKFILE}" "${value.PUBFILE}" "${value.OPURI}"
          '') sshcfg
        )
        + ''
          # 9. Request to re-run darwin-rebuild switch if new keys are generated
          if [ $RERUN -eq 1 ]; then
            printf "\033[1;31mRerun darwin-rebuild switch as new SSH key files have been created in %s folder\033[0m\n" "$(dirname "${sshcfg.NIXID.PKFILE}")"
          fi
        ''
      )
    );

    set-neovide-txt-default = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      idneovide=$(/usr/bin/osascript -e 'id of app "${Helpers.getMacAppName pkgs.neovide}"')
      # Use duti to set Neovide for plain-text (.txt) files
      # The 'all' flag applies it to editor, viewer, and shell roles
      run ${pkgs.duti}/bin/duti -s $idneovide public.plain-text all
      run ${pkgs.duti}/bin/duti -s $idneovide .txt all
      run ${pkgs.duti}/bin/duti -s $idneovide .log all
    '';
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "26.05";
}
# vim: set ts=2 sw=2 et ft=nix:
