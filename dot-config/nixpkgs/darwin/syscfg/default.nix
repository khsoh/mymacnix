{ lib, ... }:
{
  imports = [
    ./syscfg.nix
    ./mod_gh.nix
    ./mod_sshkeys.nix
  ];

  mod_gh.enable = lib.mkDefault true; 
}
