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

  nixbldstr = builtins.exec [ "bash" "-c" ''echo \"$(dscl . -read /Groups/nixbld PrimaryGroupID)\"''];
  buildGroupID = lib.strings.toInt (builtins.elemAt (lib.strings.splitString " " nixbldstr) 1);
in {
  imports = [ 
    <home-manager/nix-darwin> 
    ./brews.nix
    ./machine.nix
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
    nerd-fonts.fira-mono
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
      python3

      ### The following are for kickstart.nvim
      ripgrep
      unzip
      wget
      fd

      openssh # Install this as macOS disables use of HW security keys for SSH

      bat
      tmux
      gnused
      git
      git-credential-manager
      git-lfs
      git-repo
      git-filter-repo
      gh
      tree
      jq
      # dhall-json  ## Remove this because the nds alias can be used instead
      rectangle
      _1password-cli
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
      audacity
      ttyplot
      fastfetch
      zig
      btop

# The following packages that could not be installed because these are marked as broken
      # handbrake

# The following packages that could not be installed because these cannot be executed
      # _1password-gui
    ] ++ lib.lists.flatten (lib.lists.optionals (!config.machineInfo.is_vm) [
      kitty
      (lib.lists.optional (!(ghostty.meta ? "broken") || !ghostty.meta.broken) ghostty)
    ]);

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Setup aliases
  environment.interactiveShellInit = ''
  alias nds="nix --extra-experimental-features nix-command derivation show"
  alias nie="nix-instantiate --eval"
  alias drb="darwin-rebuild build --option allow-unsafe-native-code-during-evaluation true"
  alias drs="darwin-rebuild switch --option allow-unsafe-native-code-during-evaluation true"
  alias drlg="darwin-rebuild --list-generations"
  alias ..="cd .."
  ${pkgs.fastfetch}/bin/fastfetch
  '';

  # Auto upgrade nix package
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
  
  #!!!! Removed by nix-darwin commit 1d9f622
  # # For /etc/hosts - do not publicize contents for security reasons
  # networking.hostFiles = [ "/etc/hosts.private" ];

  # Add sudo_local security services
  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

##### Sample code for system.activationScripts.*.text - this is undocumented
###     stuff from nix-darwin
  system.activationScripts.preUserActivation.text = ''
    if ! /opt/homebrew/bin/brew --version > /dev/null 2>&1 ; then
      echo "Installing Homebrew"
      NONINTERACTIVE=1 ${pkgs.bashInteractive}/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    '';
  # system.activationScripts.postActivation.text = lib.mkAfter ''
  #   echo "I am in PostActivation"
  #   '';

# Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  ids.gids.nixbld = buildGroupID;
}
