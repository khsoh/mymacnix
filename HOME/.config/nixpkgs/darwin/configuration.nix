{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs;
    [ vim
      neovim
      tmux
      git
      git-lfs
      git-repo
      gh
      tree
      dhall-json
      rectangle
      stow
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

  imports = [ <home-manager/nix-darwin> ];
  users.users.rxdev = {
    name = "rxdev";
    home = "/Users/rxdev";
  };
  home-manager.users.rxdev = { pkgs, ... }: {
    home.packages = with pkgs;
    [ 
      (nerdfonts.override { fonts = [ "FiraMono" ]; })
    ];

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
  };

# Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
