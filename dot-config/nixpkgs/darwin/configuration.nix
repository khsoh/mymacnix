{ config, pkgs, lib, ... }:

let
  usersys = import ./usersys.nix;
  USER = usersys.USER;
  HOME = usersys.HOME;
  SYSPATH = usersys.NIXSYSPATH;
  _NIXIDFILE = "${HOME}/.ssh/nixid_ed25519";
  AGEIDFILE = (lib.trivial.throwIfNot (builtins.pathExists _NIXIDFILE) ''
  ${_NIXIDFILE} ssh key file absent
  '') _NIXIDFILE;

in {
  imports = [ 
    <home-manager/nix-darwin> 
    <agenix/modules/age.nix>
    ];

  ##### agenix configurations
  age.identityPaths = [ "${AGEIDFILE}" ];
  age.secrets.config-private = {
# file should be a path expression, not a string expression (in quotes)
    file = ~/.config/nixpkgs/secrets/config-private.age;

# path should be a string expression (in quotes), not a path expression
# IMPORTANT: READ THE DOCUMENTATION on age.secrets.<name>.path if
# you ever
    path = "${HOME}/.config/git/config-private";

# The default is true if not specified.  We want to make sure that
# the "file" (decrypted secret) is symlinked and not generated directly into
# that location
    symlink = true;

# The following are needed to ensure the decrypted secret has the correct
# owner and permission
    mode = "600";
    owner = "${USER}";
    group = "staff";
  };
  ##### End agenix configurations

  users.users.${USER} = {
    name = "${USER}";
    home = "${HOME}";

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
      dhall-json
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
  environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Setup aliases
  environment.interactiveShellInit = ''
  alias nds="nix --extra-experimental-features nix-command derivation show"
  alias nie="nix-instantiate --eval"
  alias nvmx="EIDTOR=nvim agenix -i ${AGEIDFILE}"
  alias vmx="agenix -i ${AGEIDFILE}"
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
