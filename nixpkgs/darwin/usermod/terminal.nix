{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  isVM = osConfig.machineInfo.is_vm;
in
{
  ## Terminal program for user
  options.terminal = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.ghostty-bin pkgs.kitty ]";
      description = ''
        A list of terminal packages to install.  The first package in
        the list is the default terminal to execute at startup.
      '';
    };
  };

  ## Setup checks and asserts for the SSH private and public key files based on
  ## user configuration
  config.assertions = [
    {
      assertion = (!isVM) || (!builtins.elem pkgs.kitty config.terminal.packages);
      message = ''
        kitty terminal program cannot be installed in a VM because VM does not support OpenGL drivers.
        Current terminal packages:

        ${lib.concatMapStringsSep "\n" (name: name) (
          map (pkg: "pkgs.${pkg.pname or "unknown"}") config.terminal.packages
        )}
      '';
    }
  ];
}
# vim: set ts=2 sw=2 et ft=nix:
