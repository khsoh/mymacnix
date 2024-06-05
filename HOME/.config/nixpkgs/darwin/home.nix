{ config, pkgs, ... }: 
let
  USERHOME = builtins.getEnv "HOME";
in {
  ## Need to install nerdfonts here instead of nix-darwin's users.users
  ## because nix-darwin did not link the fonts to ~/Library/Fonts folder
  home.packages = with pkgs;
  [ 
    (nerdfonts.override { fonts = [ "FiraMono" ]; })
  ];

  launchd.enable = true;
  launchd.agents = {
    updateTmuxPlugins = {
      enable = true;
      config = {
        Label = "updateTmuxPlugins";
        ProgramArguments = [ "/bin/bash"
          "-c"
          "[ -d ${USERHOME}/.tmux/plugins/tpm ] || ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm.git ${USERHOME}/.tmux/plugins/tpm ;
           ${pkgs.tmux}/bin/tmux -c \"${USERHOME}/.tmux/plugins/tpm/bindings/install_plugins\"
           ${pkgs.tmux}/bin/tmux -c \"${USERHOME}/.tmux/plugins/tpm/scripts/update_plugin.sh all\"
          "];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${USERHOME}/log/tmuxupdate.log";
        StandardErrorPath = "${USERHOME}/log/tmuxupdateError.log";
      };
    };
    updateNvimPlugins = {
      enable = true;
      config = {
        Label = "updateNvimPlugins";
        ProgramArguments = [ "${pkgs.neovim}/bin/nvim"
          "--headless"
          "+Lazy! sync"
          "+MasonUpdate"
          "+MasonToolsUpdateSync"
          "+qa"
          ];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        StandardOutputPath = "${USERHOME}/log/nvimupdate.log";
        StandardErrorPath = "${USERHOME}/log/nvimupdateError.log";
      };
    };
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.11";
}

