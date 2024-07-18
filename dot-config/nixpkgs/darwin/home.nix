{ osConfig, pkgs, lib, ... }:
let
  syscfg = osConfig.sysopt;
  ghcfg = osConfig.mod_gh;
  sshcfg = osConfig.mod_sshkeys;
  onepasscfg = osConfig.mod_1password;
  self = osConfig.home-manager.users.${syscfg.USER};
  DOTFILEPATH = ../dotfiles;

  # Function to the functionality of GNU Stow by generating
  #   links suitable for home.file.* .  The target are 
  #   linked to files in the /nix/store
  # Both srcpath must be a path variable, while targetpathstr is a string variable
  # representing the relative path to the user HOME directory.
  # The files in srcpath are copied into /nix/store before the link is generated.
  # Thus, the targets are symlinks whose source path would be immutable
  stow_hf = (srcpath: targetpathstr:
    builtins.mapAttrs (name: value: {
      enable = true;
      source = lib.path.append srcpath name;
      target = targetpathstr + "/" + name;
    }) (builtins.readDir srcpath)
  );

in {
  ### Generate the home.file for the dotfiles
  home.file = stow_hf DOTFILEPATH ".";

  imports = [
    <agenix/modules/age-home.nix>
  ];

  ##### agenix configuration
  age.identityPaths = [
    "${sshcfg.NIXIDPKFILE}"
    "${sshcfg.USERPKFILE}"
    ];

# config-private stores the git config user.email - this is the private email
# that is encrypted before checking into git
  age.secrets.config-private = {
# file should be a path expression, not a string expression (in quotes)
    file = ~/.config/nixpkgs/secrets/config-private.age;

# path should be a string expression (in quotes), not a path expression
# IMPORTANT: READ THE DOCUMENTATION on age.secrets.<name>.path if
# you ever
    path = "${self.home.homeDirectory}/.config/git/config-private";

# The default is true if not specified.  We want to make sure that
# the "file" (decrypted secret) is symlinked and not generated directly into
# that location
    symlink = true;

# The following are needed to ensure the decrypted secret has the correct permission
    mode = "600";

# Note that the owner and group attribute are absent from home-manager module
    #owner = "${syscfg.USER}";
    #group = "staff";
  };

  ##### End agenix module configuration
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
      glog = "log --graph --all";
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
          NIXDARWIN_VERSION=\$(${syscfg.NIXSYSPATH}/darwin-version --darwin-label)
          REMOTE_VERSION=\$(NIX_PATH=nixpkgs=channel:nixpkgs-unstable ${pkgs.nix}/bin/nix-instantiate --eval --expr \"(import &lt;nixpkgs&gt; {}).lib.version\"|${pkgs.gnused}/bin/sed -e 's/\"//g')
          LOCAL_VERSION=\${NIXDARWIN_VERSION%%+?*}
          LAST_LOCAL_VERSION=\$(tail ~/log/checknixpkgsError.log | ${pkgs.gnused}/bin/sed -n -e 's/LOCAL_VERSION::\s\+//p'|tail -1)

          if [[ \"$LAST_LOCAL_VERSION\" != \"$REMOTE_VERSION\" ]]; then
            &gt;&amp;2 date
            
            if [[ \"$LOCAL_VERSION\" != \"$REMOTE_VERSION\" ]]; then
              &gt;&amp;2 echo \"Checking for updates for nixpkgs\"
              &gt;&amp;2 echo \"LOCAL_VERSION::  $LOCAL_VERSION\"
              &gt;&amp;2 echo \"REMOTE_VERSION:: $REMOTE_VERSION\"
              osascript -e \"display notification \\\"Local::  $LOCAL_VERSION\\nRemote:: $REMOTE_VERSION\\\" with title \\\"New remote nixpkgs version detected\\\"\"
            else
              &gt;&amp;2 echo \"No update detected for nixpkgs\"
              &gt;&amp;2 echo \"LOCAL_VERSION::  $LOCAL_VERSION\"
            fi
          fi
          "
          ];
        RunAtLoad = true;
        StartInterval = 3600;
        StandardOutputPath = "${self.home.homeDirectory}/log/checknixpkgsOutput.log";
        StandardErrorPath = "${self.home.homeDirectory}/log/checknixpkgsError.log";
      };
    };
    LoginStartTmux = {
      enable = true;
      config = {
        Label = "LoginStartTmux";
        ProgramArguments = [
          "osascript"
          "-e" "
          tell application \"Terminal\"
            if not (exists window 1) then reopen
            activate
            set winID to id of window 1
            do script \"tmux 2>/dev/null\" in window id winID
          end tell
          return
          "
          ];
        RunAtLoad = true;
      };
    };
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
          [ -d ${self.home.homeDirectory}/.tmux/plugins/tpm ] || ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm.git ${self.home.homeDirectory}/.tmux/plugins/tpm
           &gt;&amp;2 ${pkgs.tmux}/bin/tmux -c \"${self.home.homeDirectory}/.tmux/plugins/tpm/bin/install_plugins\"
           &gt;&amp;2 ${pkgs.tmux}/bin/tmux -c \"${self.home.homeDirectory}/.tmux/plugins/tpm/bin/update_plugins all\"
           &gt;&amp;2 ${pkgs.tmux}/bin/tmux -c \"${self.home.homeDirectory}/.tmux/plugins/tpm/bin/clean_plugins\"
           &gt;&amp;2 echo \"Completed TPM plugin updates\"
          "];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${self.home.homeDirectory}/log/tmuxupdate.log";
        StandardErrorPath = "${self.home.homeDirectory}/log/tmuxupdateError.log";
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
        StandardOutputPath = "${self.home.homeDirectory}/log/nvimupdate.log";
        StandardErrorPath = "${self.home.homeDirectory}/log/nvimupdateError.log";
      };
    };
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

