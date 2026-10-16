{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Shortcut to get helper functions
  Helpers = config.helpers;
in
{
  programs.mas = {
    enable = true;
    packages = {
      "Telegram" = 747648890;

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
      name = "mouseless";
      greedy = true;
      postinstall = Helpers.restartApp2 "Mouseless" "mouseless";
    }
    {
      name = "discord";
      greedy = true;
    }
    {
      name = "dropbox";
      greedy = true;
    }
    {
      name = "displaylink";
      greedy = true;
      postinstall = Helpers.restartApp "DisplayLink Manager";
    }
    {
      name = "loopback";
      greedy = true;
    }
    {
      name = "audio-hijack";
      greedy = true;
    }
    {
      name = "obs";
      greedy = true;
    }
    {
      name = "youlean-loudness-meter";
      greedy = true;
    }
    {
      name = "bazecor";
      greedy = true;
    }
    {
      name = "ibkr";
      greedy = true;
    }
  ];

  ## Host-specific info for networking
  networking = {
    hostName = "MacBook-Pro";
    localHostName = "MacBook-Pro";
    computerName = "MacBook-Pro";
  };

  system.defaults.dock.persistent-apps = [
    "/System/Applications/Calendar.app"
    "/System/Applications/Contacts.app"
    "/System/Applications/Messages.app"
    "/System/Applications/Phone.app"
    "/System/Applications/iPhone Mirroring.app"
    "/System/Applications/Photos.app"
    "/System/Applications/Notes.app"
    "/System/Applications/Reminders.app"
  ];
}
