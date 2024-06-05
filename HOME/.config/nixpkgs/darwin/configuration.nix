{ config, pkgs, lib, ... }:

let
  USER = builtins.getEnv "USER";
  USERHOME = builtins.getEnv "HOME";
in {
  imports = [ <home-manager/nix-darwin> ];

  users.users.${USER} = {
    name = "${USER}";
    home = "${USERHOME}";

    # packages = with pkgs;
    # [
    #   ## Commented out because nix-darwin does not put the symlinks in ~/Library/Fonts
    #   ## - will move nerdfonts from home-manager back to here when nix-darwin sort out this issue
    #   ##(nerdfonts.override { fonts = [ "FiraMono" ]; })
    # ];
  };

  ## We use home-manager because this nix-darwin does not seem
  #  to handle the installation of nerdfonts correctly
  home-manager.users.${USER} = if builtins.pathExists ./home.nix then import ./home.nix else {};

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-cli"
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs;
    [ vim
      neovim

      ### The following are for kickstart.nvim
      ripgrep
      unzip
      wget
      fd

      tmux
      gnused
      git
      git-lfs
      git-repo
      gh
      tree
      dhall-json
      rectangle
      _1password
      stow
      exiftool
# The following packages are to support neovim-related builds
      go
      nodejs_22
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
  [[ -f ${./zshprompt} ]] && source ${./zshprompt}
  '';

  # Create /etc/bashrc
  programs.bash.enable = true;
  programs.bash.interactiveShellInit = ''
  [[ -f ${./bashprompt} ]] && source ${./bashprompt}
  '';

# Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
