{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.mas.enable = lib.mkForce false;

  homebrew.brews = lib.mkForce [ ];
  homebrew.casks = lib.mkForce [ ];

  networking.localHostName = config.networking.hostName;
}
