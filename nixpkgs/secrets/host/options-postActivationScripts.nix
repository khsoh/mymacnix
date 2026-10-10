{
  osConfig,
  config,
  options,
  pkgs,
  lib,
  ...
}:
builtins.seq [ osConfig config pkgs options ] {
  options.postActivationScriptText = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "System post-activation script";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
