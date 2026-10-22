{
  pkgs,
  lib,
  config,
  userInfo,
  ...
}:
builtins.seq [ lib config userInfo ] {
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
