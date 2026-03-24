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
  defaultTermPackages = [
    pkgs.ghostty-bin
  ]
  ++ (lib.optionals (!isVM) [
    pkgs.kitty
  ]);

  ## Function to extract first 2 elements of the public key file
  mkAbsPath =
    filePath:
    let
      absfile =
        if builtins.substring 0 1 filePath == "~" then
          user.home + builtins.substring 1 (builtins.stringLength filePath) filePath
        else
          filePath;
    in
    absfile;

  readPubkey =
    pubkeyfile:
    let
      absfile = mkAbsPath pubkeyfile;
      # Read the file and strip the trailing newline
      content = lib.removeSuffix "\n" (builtins.readFile absfile);
      # Split by spaces into a list of strings
      parts = lib.splitString " " content;
    in
    # Take the first two elements and join them with a space
    builtins.concatStringsSep " " (lib.take 2 parts);

  cfgsec = osConfig.secrets.target.user;
  onepasscfg = osConfig.secrets.target.host.onepassword;
  sshcfg = cfgsec.sshcfg;
  sshpkfile = if sshcfg != null then sshcfg.PKFILE else null;
  sshpubfile = if sshcfg != null then sshcfg.PUBFILE else null;
  sshpubkey = if sshcfg != null then sshcfg.pubkey else null;

  default_usercfg = ./default_usercfg.nix;
  default_usercfgFile = toString default_usercfg;

  usercfg = ./usercfg.nix;
  usercfgFile = toString usercfg;

in
{
  imports = [
    ./github.nix
    ./gitlab.nix
    ./terminal.nix
  ]
  ++ lib.optional (builtins.pathExists usercfgFile) usercfg;

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

  ## Setup checks and asserts for the SSH private and public key files based on
  ## user configuration
  config.assertions = [
    # Check the private key file
    {
      assertion = (sshpkfile == null) || (builtins.pathExists (mkAbsPath sshpkfile));
      message = "The ${sshpkfile} SSH private key file is absent - file must be present to build";
    }

    # The the public key file contents and pubkey match
    {
      assertion =
        (sshpubfile == null)
        || (!builtins.pathExists (mkAbsPath sshpubfile))
        || ((readPubkey sshpubfile) == sshpubkey);
      message = "Contents of ${sshpubfile} do not match with the pubkey string";
    }

    # If 1Password is enabled then should not use key files
    # If 1Password is disabled then must use key files
    {
      assertion =
        (onepasscfg.enable && (sshpkfile == null)) || ((!onepasscfg.enable) && (sshpkfile != null));
      message =
        if onepasscfg.enable then
          "config.secrets.target.host.onepassword.enable is true - should not not define sshcfg.PKFILE in ${<darwin-secrets>}/user/${cfgsec.name}"
        else
          "config.secrets.target.host.onepassword.enable is false - must define sshcfg.PKFILE in ${<darwin-secrets>}/user/${cfgsec.name}";
    }
  ];

}
# vim: set ts=2 sw=2 et ft=nix:
