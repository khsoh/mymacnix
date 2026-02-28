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
    ## NIXID SSH key configuration
    NIXID = {
      OPURI = lib.mkDefault "op://NIX Bootstrap/NIXID SSH Key";
      PKFILE = lib.mkDefault "${homeDir}/.ssh/nixid_ed25519";
      PUBFILE = lib.mkDefault "${homeDir}/.ssh/nixid_ed25519.pub";
    };

    ## User SSH key configuration
    USER = lib.mkIf (!isVM) {
      OPURI = lib.mkDefault "op://Private/OPENSSH ED25519 Key";
      PKFILE = lib.mkDefault "${homeDir}/.ssh/id_ed25519";
      PUBFILE = lib.mkDefault "${homeDir}/.ssh/id_ed25519.pub";
    };
  };

  ## Setup checks and asserts for the SSH private and public key files based on
  ## user configuration
  config.assertions = lib.flatten (
    lib.mapAttrsToList (name: value: [
      # Check the private key file
      {
        assertion = builtins.pathExists value.PKFILE;
        message = "The ${name} SSH private key file is absent - file must be present to build";
      }
      # Check the public key file
      {
        assertion = builtins.pathExists value.PUBFILE;
        message = "The ${name} SSH public key file is absent - file must be present to build";
      }
    ]) config.sshkeys
  );

  ##### onepassword configuration
  config.onepassword = {
    enable = lib.mkDefault (!isVM);
    SSHSIGN_PROGRAM = lib.mkDefault "${osConfig.helpers.getMacBundleAppName pkgs._1password-gui}/Contents/MacOS/op-ssh-sign";
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
