{ config, pkgs, lib, ... }:
let
  ## List of users to apply home-manager configuration on
  # Specified as a list of attribute sets that is same
  # as users.users.<name> element
  hmUsers = [
    {
      name = builtins.getEnv "USER";
      home = builtins.getEnv "HOME";
    }
  ];

in {
  imports = [ 
    <home-manager/nix-darwin> 
    ];

  ######### Configuration of modules #########

  ##### home-manager configuration

  ## We use home-manager because this nix-darwin does not seem
  #  to handle the installation of nerdfonts correctly
  #  Note that a function (not attribute) is to be bound to home-manager.users.<name>
  #  Also, it seems that this is a better way to perform user-specific configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  ## Apply home-manager configuration for all users
  home-manager.users = lib.attrsets.genAttrs
    (builtins.map ({name, home}: name) hmUsers)
    (_: import ./home.nix );

  ##### end home-manager configuration

  ######### End configuration of modules #########


  ## The following is needed by home-manager to set the
  ##  home.username and home.homeDirectory attributes
  users.users = builtins.listToAttrs
    (builtins.map ({name, home}@value: { inherit name; value = value; }) hmUsers);

  fonts.packages = with pkgs;
  [
    (nerdfonts.override { fonts = [ "FiraMono" ]; })
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-cli"
  ];

  # Setup user specific logfile rotation for all users
  environment.etc = builtins.listToAttrs
    (builtins.map ({name, home}@value: { 
      name = "newsyslog.d/${name}.conf";
      value = {
        text = ''
          ${home}/log/*.log      644  5  1024  *  NJ
          '';
      }; }) hmUsers);

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs;
    [ vim
      neovim
      (callPackage <agenix/pkgs/agenix.nix> {})

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
      jq
      # dhall-json  ## Remove this because the nds alias can be used instead
      rectangle
      _1password
### Sample demo to use overrideAttrs to embed a postPhase in the installation
      # (_1password-gui.overrideAttrs {
      #   postPhases = [ "mypostrun" ];
      #   mypostrun = ''
      #   echo "Hello World!!!!!"
      #   echo "This is a postPhase that is executed after installation"
      #   '';
      # })
      stow
      cargo
      mupdf
      exiftool
# The following packages are to support neovim-related builds
      go
      nodejs_22

      vlc-bin

# The following packages that could not be installed because these are marked as broken
      # handbrake

# The following packages that could not be installed because these cannot be executed
      # _1password-gui
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Setup aliases
  environment.interactiveShellInit = ''
  alias nds="nix --extra-experimental-features nix-command derivation show"
  alias nie="nix-instantiate --eval"
  alias drb="darwin-rebuild build"
  alias drs="darwin-rebuild switch"
  alias drlg="darwin-rebuild --list-generations"
  alias cdsec="cd ~/.config/nixpkgs/secrets"
  alias ..="cd .."
  '';

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

##### Sample code for system.activationScripts.*.text - this is undocumented
###     stuff from nix-darwin
  # system.activationScripts.preActivation.text = ''
  #   echo "I am in PreActivation"
  #   '';
  # system.activationScripts.postActivation.text = lib.mkAfter ''
  #   echo "I am in PreActivation"
  #   '';

# Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
