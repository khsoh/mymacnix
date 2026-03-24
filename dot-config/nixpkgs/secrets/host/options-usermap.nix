{ lib, ... }:
{
  options.usermap = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    example = {
      alexander = "alex";
      benjamin = "ben";
    };
    description = ''
      An attribute set mapping the username in the current host to folder names under the 
      <darwin-secrets>/user directory.
    '';
    default = {
      __default__ = "__default__";
    };
  };
}
# vim: set ts=2 sw=2 et ft=nix:
