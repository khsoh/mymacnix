{ osConfig, pkgs, lib, ... }:
let
  syscfg = osConfig.sysopt;
  ghcfg = osConfig.mod_gh;
  sshcfg = osConfig.mod_sshkeys;
  onepasscfg = osConfig.mod_1password;
  DOTFILEPATH = ../dotfiles;


  # Function to the functionality of GNU Stow by generating
  #   links suitable for home.file .  The target are 
  #   linked to files in the /nix/store
  # Both srcpath and targetpath must be path variables
  # The files in srcpath are copied into /nix/store before the link is generated 
  #   - hence the targets are immutable
  stow_hf = (srcpath: targetpathstr:
    builtins.mapAttrs (name: value: {
      enable = true;
      source = lib.path.append srcpath name;
      target = targetpathstr + "/" + name;
    }) (builtins.readDir srcpath)
  );

in {
  ## Need to install nerdfonts here instead of nix-darwin's users.users
  ## because nix-darwin did not link the fonts to ~/Library/Fonts folder
  home.packages = with pkgs;
  [ 
    (nerdfonts.override { fonts = [ "FiraMono" ]; })
  ];

  ### Generate the home.file for the dotfiles
  home.file = stow_hf DOTFILEPATH ".";

  ### Enable git configuration
  programs.git = {
    enable = true;
    userName = "K H Soh";

    aliases = {
      co = "checkout";
      ci = "commit";
      br = "branch";
      st = "status";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
    };

    includes = [
      { ### The following allows user to specify their config file that contains private
        #   information (like email) that they may not want to place in a public repo
        path = "~/.config/git/config-private";
      }
    ]
    ++ lib.lists.optionals ghcfg.enable
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
        ssh = if onepasscfg.sshsign_pgm_present then {
          program = onepasscfg.SSHSIGN_PROGRAM;
        } else {} ;
      };
      commit = { gpgsign = true; };
      tag = { gpgsign = true; };

      rerere = { enabled = true; };
      rebase = { updateRefs = true; };
    };

  };

  launchd.enable = true;
  launchd.agents = {
    LoginStartTmux = {
      enable = true;
      config = {
        Label = "LoginStartTmux";
        ProgramArguments = [ "${syscfg.HOME}/.config/tmux/osx_tmux_terminal_startup.sh" ];
        RunAtLoad = true;
      };
    };
    updateTmuxPlugins = {
      enable = true;
      config = {
        Label = "updateTmuxPlugins";
        ProgramArguments = [ "${syscfg.NIXSYSPATH}/bash"
          "-l"
          "-c"
          "[ -d ${syscfg.HOME}/.tmux/plugins/tpm ] || ${syscfg.NIXSYSPATH}/git clone https://github.com/tmux-plugins/tpm.git ${syscfg.HOME}/.tmux/plugins/tpm
           &gt;&amp;2 ${syscfg.NIXSYSPATH}/tmux -c \"${syscfg.HOME}/.tmux/plugins/tpm/bin/install_plugins\"
           &gt;&amp;2 ${syscfg.NIXSYSPATH}/tmux -c \"${syscfg.HOME}/.tmux/plugins/tpm/bin/update_plugins all\"
           &gt;&amp;2 ${syscfg.NIXSYSPATH}/tmux -c \"${syscfg.HOME}/.tmux/plugins/tpm/bin/clean_plugins\"
           &gt;&amp;2 echo \"Completed TPM plugin updates\"
          "];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${syscfg.HOME}/log/tmuxupdate.log";
        StandardErrorPath = "${syscfg.HOME}/log/tmuxupdateError.log";
      };
    };
    updateNvimPlugins = {
      enable = true;
      config = {
        Label = "updateNvimPlugins";
        ProgramArguments = [ "${syscfg.NIXSYSPATH}/bash"
          "-l"
          "-c"
          "${syscfg.NIXSYSPATH}/nvim --headless \"+Lazy! sync\" \"+MasonUpdate\" \"+MasonToolsUpdateSync\" \"+qa\" "
          ];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${syscfg.HOME}/log/nvimupdate.log";
        StandardErrorPath = "${syscfg.HOME}/log/nvimupdateError.log";
      };
    };

  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.11";
}

