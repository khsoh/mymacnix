{
  osConfig,
  config,
  options,
  pkgs,
  lib,
  ...
}:
builtins.seq [ osConfig config pkgs ] {
  options.services = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = options.services.definitions or [ ];
    };
    default = { };
    description = "Host-specific services configuration.";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
