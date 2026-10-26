{
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  darwinsecrets = osConfig.helpers.getNixPathEntry "darwin-secrets";

  defaultTermPackages = [
    pkgs.ghostty-bin
  ];

  cfgsec = osConfig.secrets.target.user;
  cfghost = osConfig.secrets.target.host;
  install_onepassword = osConfig.install_onepassword;
  sshcfg = cfgsec.sshcfg;
  sshpkfile = if sshcfg != null then sshcfg.PKFILE else null;

  default_usercfg = ./default_usercfg.nix;
  default_usercfgFile = toString default_usercfg;

  usercfg = ./usercfg.nix;
  usercfgFile = toString usercfg;

in
{
  imports = [
    ./github.nix
    ./gitlab.nix
    ./codeberg.nix
    ./terminal.nix
    ./hardlinks.nix
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

  ##### codeberg configuration
  config.codeberg = {
    enable = lib.mkDefault true;
    username = lib.mkDefault "khsoh";
  };

  #### terminal configuration
  config.terminal = {
    packages = lib.mkDefault defaultTermPackages;
  };

  #### Create a default usercfg.nix in ~/.config/nix and add a symbolic link to it
  config.home.activation.linkusercfg = lib.mkIf (!(builtins.pathExists usercfgFile)) (
    lib.hm.dag.entryAfter [ "writeBoundary" ]
      # bash
      ''
        noteEcho "Copying user configuration settings to ${usercfgFile}"
        if [ ! -f "${usercfgFile}" ]; then
          run cp "${default_usercfgFile}" "${usercfgFile}"
        fi
      ''
  );

  ## Setup checks and asserts for the SSH private and public key files based on
  ## user configuration
  config.assertions = [
    # If 1Password is enabled then should not use key files
    # If 1Password is disabled then must use key files
    {
      assertion =
        (install_onepassword && (sshpkfile == null)) || ((!install_onepassword) && (sshpkfile != null));
      message =
        if install_onepassword then
          "The onepassword.enable flag is set to true in ${darwinsecrets}/host/${cfghost.name}/default.nix - so the sshcfg.PKFILE must be set to null in ${darwinsecrets}/user/${cfgsec.name}/default.nix"
        else
          "The onepassword.enable flag is set to false in ${darwinsecrets}/host/${cfghost.name}/default.nix - so the sshcfg.PKFILE must be defined in ${darwinsecrets}/user/${cfgsec.name}/default.nix";
    }
  ];
}
# vim: set ts=2 sw=2 et ft=nix:
