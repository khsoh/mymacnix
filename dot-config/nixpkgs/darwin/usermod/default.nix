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
  default_usercfgFile = toString default_usercfg;

  usercfgTarget = ./usercfg.nix; # This will be a symbolic link to the usercfgSourceFile
  usercfgTargetFile = toString usercfgTarget;
  usercfgSourceFile = "${config.xdg.configHome}/nix/usercfg.nix";
in
{
  imports = [
    ./github.nix
    ./gitlab.nix
    ./onepassword.nix
    ./sshkeys.nix
    ./terminal.nix
  ]
  ++ lib.optional (builtins.pathExists usercfgTarget) usercfgTarget;

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
  config.home.activation.linkusercfg = lib.mkIf (!builtins.pathExists usercfgTarget) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      noteEcho "Linking user configuration settings to ${usercfgSourceFile}"
      run mkdir -p "$(dirname "${usercfgSourceFile}")"
      if [ ! -f "${usercfgSourceFile}" ]; then
        noteEcho "Missing ${usercfgSourceFile}: Creating default from ${default_usercfgFile}"
        run cp "${default_usercfgFile}" "${usercfgSourceFile}"
      fi
      run ln -sf "${usercfgSourceFile}" "${usercfgTargetFile}"
    ''
  );
}
# vim: set ts=2 sw=2 et ft=nix:
