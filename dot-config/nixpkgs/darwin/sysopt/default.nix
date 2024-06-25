{ lib, ... }:
{
  imports = [
    ./sysopt.nix
    ./mod_gh.nix
    ./mod_sshkeys.nix
    ./mod_1password.nix
  ];

  mod_gh.enable = lib.mkDefault true; 
}
