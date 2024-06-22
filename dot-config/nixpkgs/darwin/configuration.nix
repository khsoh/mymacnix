{ config, pkgs, lib, ... }:
let
  syscfg = config.sysopt;
  sshcfg = config.mod_sshkeys;

  # Default SSH private key file to use in alias for agenix - depends on presence of the private key file
  DEFAULT_PKFILE = if sshcfg.userpkfile_present then sshcfg.USERPKFILE else sshcfg.NIXIDPKFILE;

in {
  imports = [ 
    <home-manager/nix-darwin> 
    <agenix/modules/age.nix>
    ./cfg.nix  # Setup the config for this particular system
    ];

  ##### agenix configurations
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
    path = "${syscfg.HOME}/.config/git/config-private";

# The default is true if not specified.  We want to make sure that
# the "file" (decrypted secret) is symlinked and not generated directly into
# that location
    symlink = true;

# The following are needed to ensure the decrypted secret has the correct
# owner and permission
    mode = "600";
    owner = "${syscfg.USER}";
    group = "staff";
  };
  ##### End agenix configurations

  users.users.${syscfg.USER} = {
    name = "${syscfg.USER}";
    home = "${syscfg.HOME}";

    # packages = with pkgs;
    # [
    #   ## Commented out because nix-darwin does not put the symlinks in ~/Library/Fonts
    #   ## - will move nerdfonts from home-manager back to here when nix-darwin sort out this issue
    #   ##(nerdfonts.override { fonts = [ "FiraMono" ]; })
    # ];
  };

  ## We use home-manager because this nix-darwin does not seem
  #  to handle the installation of nerdfonts correctly
  #  Note that a function (not attribute) is to be bound to home-manager.users.<name>
  home-manager.users.${syscfg.USER} = import ./home.nix;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-cli"
  ];

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
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "${syscfg.HOME}/.config/nixpkgs/darwin/configuration.nix";

  # Setup aliases
  environment.interactiveShellInit = ''
  alias nds="nix --extra-experimental-features nix-command derivation show"
  alias nie="nix-instantiate --eval"
  alias drs="darwin-rebuild switch"
  alias nvmx="EDITOR=nvim agenix -i ${DEFAULT_PKFILE}"
  alias vmx="agenix -i ${DEFAULT_PKFILE}"
  alias cdsec="cd ~/.config/nixpkgs/secrets"
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
