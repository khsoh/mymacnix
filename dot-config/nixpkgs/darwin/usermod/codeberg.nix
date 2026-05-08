{ lib, ... }:
{
  options.codeberg = {
    enable = lib.mkEnableOption "Enables codeberg module";
    noreply_email = lib.mkOption {
      type = lib.types.str;
      description = "No reply email of your codeberg account";
      default = "";
    };
    username = lib.mkOption {
      type = lib.types.str;
      description = "Username of codeberg account";
    };
  };
}
# vim: set ts=2 sw=2 et ft=nix:
