{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  isVM = osConfig.machineInfo.is_vm;
  homeDir = config.home.homeDirectory;
  defaultTermPackages = [
    pkgs.ghostty-bin
  ]
  ++ (lib.optionals (!isVM) [
    pkgs.kitty
  ]);

  default_usercfg = ./default_usercfg.nix;
  usercfg = ./usercfg.nix;
in
{
  imports = [
    ./github.nix
    ./gitlab.nix
    ./onepassword.nix
    ./sshkeys.nix
    ./terminal.nix
  ]
  ++ lib.optional (builtins.pathExists usercfg) usercfg;

  ##### sshkeys configuration
  config.sshkeys = {
    ## The locations of the SSH private and public key files
    USERPKFILE = lib.mkDefault "${homeDir}/.ssh/id_ed25519";
    USERPUBFILE = lib.mkDefault "${homeDir}/.ssh/id_ed25519.pub";
    NIXIDPKFILE = lib.mkDefault "${homeDir}/.ssh/nixid_ed25519";
    NIXIDPUBFILE = lib.mkDefault "${homeDir}/.ssh/nixid_ed25519.pub";

    #### Test the presence of SSH key files
    ### The configuration only builds if the following files exist:
    ## - nixid SSH private key file
    ## - nixid SSH public key file
    check_nixidpkfile = lib.mkDefault true;
    check_nixidpubfile = lib.mkDefault true;
    check_userpkfile = lib.mkDefault (!isVM);
    check_userpubfile = lib.mkDefault (!isVM);

    ## 1Password CLI op URL to SSH keys
    NIXIDPKOPLOC = lib.mkDefault "op://NIX Bootstrap/NIXID SSH Key";
    USERPKOPLOC = lib.mkDefault "op://Private/OPENSSH ED25519 Key";
  };

  ##### onepassword configuration
  config.onepassword = {
    sshsign_pgm_present = lib.mkDefault (!isVM);
    SSHSIGN_PROGRAM = lib.mkDefault "/Applications/Nix Apps/1Password.app/Contents/MacOS/op-ssh-sign";
  };

  ##### github configuration
  config.github = {
    enable = lib.mkDefault true;
    username = lib.mkDefault "khsoh";
  };

  ##### gitlab configuration
  config.gitlab = {
    enable = lib.mkDefault true;
    username = lib.mkDefault "khsoh";
  };

  #### terminal configuration
  config.terminal = {
    packages = lib.mkDefault defaultTermPackages;
  };

  #### Create a default usercfg.nix in ~/.config/nix and add a symbolic link to it
  config.home.activation.linkusercfg = lib.mkIf (!builtins.pathExists usercfg) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "${config.xdg.configHome}/nix"
      if [ ! -f "${config.xdg.configHome}/nix/usercfg.nix ]; then
        cp "${toString default_usercfg}" "${config.xdg.configHome}/nix/usercfg.nix"
      fi
      ln -sf "${config.xdg.configHome}/nix/usercfg.nix" "${toString usercfg}"
    ''
  );
}
# vim: set ts=2 sw=2 et ft=nix:
