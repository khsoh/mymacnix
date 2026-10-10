{
  osConfig,
  config,
  options,
  pkgs,
  lib,
  ...
}:
builtins.seq [ osConfig config pkgs options ] {
  options.isHeadlessServer = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Indicate whether machine is a headless server";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
