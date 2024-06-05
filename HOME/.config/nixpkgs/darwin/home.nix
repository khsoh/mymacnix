{ config, pkgs, ... }: 
let
  usersys = import ./usersys.nix;
  USER = usersys.USER;
  HOME = usersys.HOME;
  SYSPATH = usersys.NIXSYSPATH;
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
        ProgramArguments = [ "${SYSPATH}/zsh"
          "-c"
          "[ -d ${HOME}/.tmux/plugins/tpm ] || ${SYSPATH}/git clone https://github.com/tmux-plugins/tpm.git ${HOME}/.tmux/plugins/tpm ;
           ${SYSPATH}/tmux -c \"${HOME}/.tmux/plugins/tpm/bindings/install_plugins\"
           ${SYSPATH}/tmux -c \"${HOME}/.tmux/plugins/tpm/scripts/update_plugin.sh all\"
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

