{
  pkgs,
  lib,
  config,
  ...
}:
{
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
