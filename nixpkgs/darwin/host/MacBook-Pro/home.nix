{
  config,
  osConfig,
  pkgs,
  lib,
  user,
  ...
}:
builtins.seq [ config osConfig pkgs user lib ] {
}
