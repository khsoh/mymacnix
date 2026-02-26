{
  config,
  osConfig,
  lib,
  ...
}:
let
  isVM = osConfig.machineInfo.is_vm;
in
{
  options.onepassword = {
    SSHSIGN_PROGRAM = lib.mkOption {
      type = lib.types.str;
      description = "Relative path to current user's secret key file";
      default = "/Applications/Nix Apps/1Password.app/Contents/MacOS/op-ssh-sign";
    };

    ## This is readOnly to determine if the SSHSIGN_PROGRAM is present
    sshsign_pgm_present = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Indicate if 1Password signing program is present.  This is only installed 
        if non-VM machines.
      '';
    };
  };
}
# vim: set ts=2 sw=2 et ft=nix:
