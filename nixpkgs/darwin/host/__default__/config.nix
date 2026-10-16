{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.mas = lib.mkForce {
    enable = false;
    packages = { };
  };

  homebrew.brews = lib.mkForce [ ];
  homebrew.casks = lib.mkForce [ ];

  networking.localHostName = config.networking.hostName;
}
