{
  config,
  osConfig,
  lib,
  pkgs,
  user,
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

  sshcfg = config.sshkeys;

  ## Function to extract first 2 elements of the public key file
  readPubkey =
    pubkeyfile:
    let
      # Read the file and strip the trailing newline
      content = lib.removeSuffix "\n" (builtins.readFile pubkeyfile);
      # Split by spaces into a list of strings
      parts = lib.splitString " " content;
    in
    # Take the first two elements and join them with a space
    builtins.concatStringsSep " " (lib.take 2 parts);

  default_usercfg = ./default_usercfg.nix;
  default_usercfgFile = toString default_usercfg;

  usercfg = ./usercfg.nix;
  usercfgFile = toString usercfg;

in
{
  imports = [
    ./github.nix
    ./gitlab.nix
    ./onepassword.nix
    ./sshkeys.nix
    ./terminal.nix
  ]
  ++ lib.optional (builtins.pathExists usercfgFile) usercfg;

  ##### sshkeys configuration
  config.sshkeys = lib.mkMerge [
    (lib.mkIf config.onepassword.enable {
      OPURI = lib.mkDefault "op://Private/OPENSSH ED25519 Key";
      pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBUfgkqOXhnONi4FAsFfZFeqW0Bkij6c/6zJf8Il1oCX";
    })
    (lib.mkIf (!config.onepassword.enable) {
      OPURI = lib.mkDefault "op://NIX Bootstrap/NIXID SSH Key";
      PKFILE = lib.mkDefault "${homeDir}/.ssh/nixid_ed25519";
      PUBFILE = lib.mkDefault "${homeDir}/.ssh/nixid_ed25519.pub";

      # Read from PUBFILE if it exists
      pubkey = lib.mkDefault (if (sshcfg.PUBFILE != null) then (readPubkey sshcfg.PUBFILE) else null);
    })
  ];

  ## Setup checks and asserts for the SSH private and public key files based on
  ## user configuration
  config.assertions = [
    # Check the private key file
    {
      assertion = (sshcfg.PKFILE == null) || (builtins.pathExists sshcfg.PKFILE);
      message = "The ${sshcfg.PKFILE} SSH private key file is absent - file must be present to build";
    }

    # Check the public key file
    {
      assertion = (sshcfg.PUBFILE == null) || (builtins.pathExists sshcfg.PUBFILE);
      message = "The ${sshcfg.PUBFILE} SSH public key file is absent - file must be present to build";
    }

    # The the public key file contents and pubkey match
    {
      assertion = (sshcfg.PUBFILE == null) || ((readPubkey sshcfg.PUBFILE) == sshcfg.pubkey);
      message = "Contents of ${sshcfg.PUBFILE} do not match with the pubkey string";
    }

    # If 1Password is enabled then should not use key files
    # If 1Password is disabled then must use key files
    {
      assertion =
        (config.onepassword.enable && (sshcfg.PKFILE == null) && (sshcfg.PUBFILE == null))
        || ((!config.onepassword.enable) && (sshcfg.PKFILE != null) && (sshcfg.PUBFILE != null));
      message =
        if config.onepassword.enable then
          "onepassword.enable is true - should not not define sshkeys.PKFILE nor sshkeys.PUBFILE"
        else
          "onepassword.enable is false - must define sshkeys.PKFILE nor sshkeys.PUBFILE";
    }
  ];

  ##### onepassword configuration
  config.onepassword = {
    enable = lib.mkDefault (user.hasAppleID);
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
  config.home.activation.linkusercfg = lib.mkIf (!(builtins.pathExists usercfgFile)) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      noteEcho "Copying user configuration settings to ${usercfgFile}"
      if [ ! -f "${usercfgFile}" ]; then
        run cp "${default_usercfgFile}" "${usercfgFile}"
      fi
    ''
  );
}
# vim: set ts=2 sw=2 et ft=nix:
