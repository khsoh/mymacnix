{ lib, ... }:
{
  options.github = {
    enable = lib.mkEnableOption "Enables github module";
    noreply_email = lib.mkOption {
      type = lib.types.str;
      description = "No reply email of your github account";
      default = "";
    };
    username = lib.mkOption {
      type = lib.types.str;
      description = "Username of github account";
    };
  };

  config.github = {
    enable = lib.mkDefault true;
    username = "khsoh";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
