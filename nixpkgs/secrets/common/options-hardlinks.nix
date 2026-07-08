{
  config,
  lib,
  options,
  ...
}:
import (<darwin-config> + "/usermod/hardlinks.nix") { inherit config lib options; }
# vim: set ts=2 sw=2 et ft=nix:
