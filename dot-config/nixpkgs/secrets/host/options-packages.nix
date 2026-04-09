{ lib, ... }:
{
  options.hostPackages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    example = lib.literalExpression "[ pkgs.firefox pkgs.brave ]";
    description = ''
      Set of host-specific packages to be appended to environment.systemPackages
    '';
  };
}
# vim: set ts=2 sw=2 et ft=nix:
