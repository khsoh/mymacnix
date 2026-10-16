{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.mas = {
    enable = true;
    packages = {
      "Xcode" = 497799835;
      "Cursor Pro" = 1447043133;
      "Bible Study" = 472790630;
      "Amazon Kindle" = 302584613;
      "Drafts" = 1435957248;
      "MoneyWiz" = 1511185140;

      ## Apple Apps
      "Keynote" = 361285480;
      "Numbers" = 361304891;
      "Pages" = 361309726;
      "iMovie" = 408981434;
    };
  };

  homebrew.casks = [
    {
      name = "discord";
      greedy = true;
    }
  ];

  ## Host-specific info for networking
  networking = {
    hostName = "Sohs-Mac-mini";
    localHostName = "Sohs-Mac-mini";
    computerName = "Soh's Mac mini";
  };
}
