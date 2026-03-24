{ config, lib, ... }:
{
  options.deployment = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          OPURI = lib.mkOption {
            type = lib.types.str;
            description = "1Password URI secret reference";
          };
          FILE = lib.mkOption {
            type = lib.types.str;
            description = "Path to deployed file";
          };
          POSTCMD = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "A list of commands to execute after deployment";
          };
        };
      }
    );
    default = [ ];
    description = "A list of deployments";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
