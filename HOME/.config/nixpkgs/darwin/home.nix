{ config, pkgs, ... }: 
{
  ## Need to install nerdfonts here instead of nix-darwin's users.users
  ## because nix-darwin did not link the fonts to ~/Library/Fonts folder
  home.packages = with pkgs;
  [ 
    (nerdfonts.override { fonts = [ "FiraMono" ]; })
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.11";
}

