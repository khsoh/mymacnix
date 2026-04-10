{ lib, options, ... }:
{
  ## Define host-specific homebrew options
  options.hostbrew = {
    brews = lib.mkOption {
      type = options.homebrew.brews.type;
      default = [ ];
      description = ''
        Set of host-specific homebrew brews packages
      '';
    };

    casks = lib.mkOption {
      type = options.homebrew.casks.type;
      default = [ ];
      description = ''
        Set of host-specific homebrew casks packages
      '';
    };

    masApps = lib.mkOption {
      type = options.homebrew.masApps.type;
      default = [ ];
      description = ''
        Set of host-specific homebrew masApps packages
      '';
    };
  };

  config.hostbrew.brews = lib.mkBefore [
    "exercism"
    "mas"
  ];

  config.hostbrew.casks = lib.mkBefore [
    {
      name = "whatsapp";
      greedy = true;
    }
    {
      name = "signal";
      greedy = true;
    }
    {
      name = "google-drive";
      greedy = true;
    }
    {
      name = "logos";
      greedy = true;
    }
    {
      name = "microsoft-office";
      greedy = true;
    }
    {
      name = "zoom";
      greedy = true;
    }
    {
      name = "affinity";
      greedy = true;
    }
    {
      name = "handbrake-app";
      greedy = true;
    }
    {
      name = "yubico-authenticator";
      greedy = true;
    }
    {
      name = "dropbox";
      greedy = true;
    }
  ];

  config.hostbrew.masApps = lib.mkBefore {
    "Cursor Pro" = 1447043133;
    "Bible Study" = 472790630;
    "1Password for Safari" = 1569813296;
    "Kindle" = 302584613;
    "Drafts" = 1435957248;
    "CleanMyMac" = 1339170533;

    ## Apple Apps
    "Keynote" = 409183694;
    "Numbers" = 409203825;
    "Pages" = 409201541;
    "iMovie" = 408981434;
  };
}
# vim: set ts=2 sw=2 et ft=nix:
