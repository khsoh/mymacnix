{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.mas.enable = false;

  homebrew.brews = lib.mkForce [ ];
  homebrew.casks = lib.mkForce [ ];

  networking.localHostName = config.networking.hostName;
}
