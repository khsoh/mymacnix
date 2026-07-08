{ lib, ... }:
{
  options.gitlab = {
    enable = lib.mkEnableOption "Enables gitlab module";
    noreply_email = lib.mkOption {
      type = lib.types.str;
      description = "No reply email of your gitlab account";
      default = "";
    };
    username = lib.mkOption {
      type = lib.types.str;
      description = "Username of gitlab account";
    };
  };
}
# vim: set ts=2 sw=2 et ft=nix:
