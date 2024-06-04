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
        ProgramArguments = [ "/usr/bin/bash"
          "-c"
          "[ -d ${USERHOME}/.tmux/plugins/tpm ] || exit ;
           for d in ${USERHOME}/.tmux/plugins/*; do
             ${pkgs.git}/bin/git -C $d pull --recurse-submodules ;
           done"
          ];
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
        ProgramArguments = [ "${pkgs.nvim}/bin/nvim"
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

