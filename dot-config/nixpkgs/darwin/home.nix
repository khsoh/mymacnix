{ config, pkgs, lib, ... }: 
let
  usersys = import ./usersys.nix;
  USER = usersys.USER;
  HOME = usersys.HOME;
  SYSPATH = usersys.NIXSYSPATH;
  DOTFILEPATH = ../dotfiles;
  gh_noreply_email = "2169449+khsoh@users.noreply.github.com";
  ssh_user_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBUfgkqOXhnONi4FAsFfZFeqW0Bkij6c/6zJf8Il1oCX";
in {
  ## Need to install nerdfonts here instead of nix-darwin's users.users
  ## because nix-darwin did not link the fonts to ~/Library/Fonts folder
  home.packages = with pkgs;
  [ 
    (nerdfonts.override { fonts = [ "FiraMono" ]; })
  ];

  ### Generate the home.file for the dotfiles
  home.file = builtins.mapAttrs (name: value:
    { enable = true;
      source = lib.path.append DOTFILEPATH name;
      target = name;
    }) (builtins.readDir DOTFILEPATH);

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

      #### The following specify noreply email for github repos
      {
        condition = "hasconfig:remote.*.url:git@github.com:*/**";
        contents = {
          user = { email = gh_noreply_email; };
        };
      }
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        contents = {
          user = { email = gh_noreply_email; };
        };
      }
      {
        condition = "hasconfig:remote.*.url:https://*@github.com/**";
        contents = {
          user = { email = gh_noreply_email; };
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
      user = { signingkey = ssh_user_pubkey; };
      gpg = {
        format = "ssh";
        ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };
      commit = { gpgsign = true; };
      tag = { gpgsign = true; };

      rerere = { enabled = true; };
      rebase = { updateRefs = true; };
    };

  };

  launchd.enable = true;
  launchd.agents = {
    updateTmuxPlugins = {
      enable = true;
      config = {
        Label = "updateTmuxPlugins";
        ProgramArguments = [ "${SYSPATH}/zsh"
          "-c"
          "[ -d ${HOME}/.tmux/plugins/tpm ] || ${SYSPATH}/git clone https://github.com/tmux-plugins/tpm.git ${HOME}/.tmux/plugins/tpm ;
           ${SYSPATH}/tmux -c \"${HOME}/.tmux/plugins/tpm/bin/install_plugins\"
           ${SYSPATH}/tmux -c \"${HOME}/.tmux/plugins/tpm/bin/update_plugins all\"
           ${SYSPATH}/tmux -c \"${HOME}/.tmux/plugins/tpm/bin/clean_plugins\"
          "];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${HOME}/log/tmuxupdate.log";
        StandardErrorPath = "${HOME}/log/tmuxupdateError.log";
      };
    };
    updateNvimPlugins = {
      enable = true;
      config = {
        Label = "updateNvimPlugins";
        ProgramArguments = [ "${SYSPATH}/zsh"
          "-c"
          "${SYSPATH}/nvim --headless \"+Lazy! sync\" \"+MasonUpdate\" \"+MasonToolsUpdateSync\" \"+qa\" "
          ];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${HOME}/log/nvimupdate.log";
        StandardErrorPath = "${HOME}/log/nvimupdateError.log";
      };
    };

  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.11";
}

