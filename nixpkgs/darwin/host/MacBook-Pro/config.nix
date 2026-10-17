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
  environment.systemPackages = with pkgs; [
    exiftool
    ttyplot

    ## Desktop and terminal related packages
    rectangle

    # Included in builds of the real thing
    ### The following are to setup use of Yubikey
    yubikey-manager
    yubico-piv-tool

    protonmail-desktop
    bitwarden-desktop

    element-desktop

    # For installing mas packages
    mas

    ## VM related stuff
    utm
    podman
    rustup

    ## Multimedia related utilities
    vlc-bin
    audacity

    ## P2P support
    iroh-ssh
  ];

  programs.mas.packages = {
    "Telegram" = 747648890;
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
