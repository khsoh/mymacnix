{ config, lib, ... }:
{
  options.install_wsgx = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Option to install Wireless@SGx mobileconfig profile";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
