{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
{
  options.onepassword = {
    SSHSIGN_PROGRAM = lib.mkOption {
      type = lib.types.str;
      default = "${osConfig.helpers.getMacBundleAppName pkgs._1password-gui}/Contents/MacOS/op-ssh-sign";
      description = "Relative path to current user's secret key file";
    };

    enable = lib.mkOption {
      type = lib.types.bool;
      default = !osConfig.machineInfo.is_vm;
      description = ''
        Indicate whether to install 1Password and CLI program
      '';
    };
  };
}
# vim: set ts=2 sw=2 et ft=nix:
