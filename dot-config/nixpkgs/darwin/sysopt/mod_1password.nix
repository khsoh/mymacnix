{ config, lib, ... }:
let
  onepasscfg = config.mod_1password;
  sshcfg = config.mod_sshkeys;
in {

  config.warnings = lib.mkIf (!onepasscfg.sshsign_pgm_present) [
    ''
      Best to install 1Password App first before deploying the Nix configuration.
      Will use ${sshcfg.NIXIDPKFILE} as the user SSH key for GIT signing
    ''
  ];
  options.mod_1password = {
    SSHSIGN_PROGRAM = lib.mkOption {
      type = lib.types.str;
      description = "Relative path to current user's secret key file";
      default = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };

    ## This is readOnly to determine if the SSHSIGN_PROGRAM is present
    sshsign_pgm_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
  };


  config.mod_1password = {
    sshsign_pgm_present = builtins.pathExists onepasscfg.SSHSIGN_PROGRAM;
  };
}
