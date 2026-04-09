{ lib, options, ... }:
{
  options.hostPackages = lib.mkOption {
    type = options.environment.systemPackages.type;
    default = [ ];
    example = lib.literalExpression "[ pkgs.firefox pkgs.brave ]";
    description = ''
      Set of host-specific packages to be appended to environment.systemPackages.
      It is same type as environment.systemPackages.
    '';
  };
}
# vim: set ts=2 sw=2 et ft=nix:
