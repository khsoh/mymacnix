{
  config,
  osConfig,
  lib,
  ...
}:
let
  onepasscfg = config.onepassword;
  sshcfg = config.sshkeys;
in
{

  config.warnings = lib.mkIf (!onepasscfg.sshsign_pgm_present && !osConfig.machineInfo.is_vm) [
    ''
      Best to install 1Password App first before deploying the Nix configuration.
      Will use ${sshcfg.NIXIDPKFILE} as the user SSH key for GIT signing
    ''
  ];
  options.onepassword = {
    SSHSIGN_PROGRAM = lib.mkOption {
      type = lib.types.str;
      description = "Relative path to current user's secret key file";
      default = "/Applications/Nix Apps/1Password.app/Contents/MacOS/op-ssh-sign";
    };

    ## This is readOnly to determine if the SSHSIGN_PROGRAM is present
    sshsign_pgm_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
  };

  config.onepassword = {
    SSHSIGN_PROGRAM = "/Applications/Nix Apps/1Password.app/Contents/MacOS/op-ssh-sign";
    sshsign_pgm_present = builtins.pathExists onepasscfg.SSHSIGN_PROGRAM;
  };
}
# vim: set ts=2 sw=2 et ft=nix:
