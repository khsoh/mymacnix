{
  pkgs,
  lib,
  config,
  ...
}:
{
  homebrew.brews = lib.mkForce [ ];
  homebrew.casks = lib.mkForce [ ];

  networking.localHostName = config.networking.hostName;
}
