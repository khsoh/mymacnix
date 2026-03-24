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
      description = "Absolute path to 1Password SSH signing program";
    };

    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Indicate whether to install 1Password and CLI program";
    };
  };
}
# vim: set ts=2 sw=2 et ft=nix:
