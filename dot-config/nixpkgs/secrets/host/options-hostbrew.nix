{
  config,
  lib,
  options,
  ...
}:
let
  ## Function to remove options and suboptions marked as internal or readOnly
  filterOptions =
    attrs:
    let
      filtered = lib.filterAttrs (
        name: value:
        let
          isOption = (value._type or "") == "option";
          isInternal = value.internal or false;
          isReadOnly = value.readOnly or false;
        in
        !(isOption && (isInternal || isReadOnly))
      ) attrs;
    in
    lib.mapAttrs (
      name: value:
      if lib.isAttrs value && value._type or "" != "option" then filterOptions value else value
    ) filtered;

  originalBrewOptionsFn = builtins.head (builtins.head (
    options.homebrew.brews.type.nestedTypes.elemType.nestedTypes.finalType.getSubModules
  )).imports;

  ## Modified brew options to remove all options marked as internal or readOnly including nested suboptions
  hostBrewOptionsFn =
    args:
    let
      result = originalBrewOptionsFn args;
    in
    {
      options = filterOptions (result.options or { });
    };

  originalCaskOptionsFn = builtins.head (builtins.head (
    options.homebrew.casks.type.nestedTypes.elemType.nestedTypes.finalType.getSubModules
  )).imports;

  ## Modified cask options to remove all options marked as internal or readOnly including nested suboptions
  hostCaskOptionsFn =
    args:
    let
      result = originalCaskOptionsFn args;
    in
    {
      options = filterOptions (result.options or { });
    };

  restartApp = config.hostbrew.helpers.restartApp;
in
{
  ## Define host-specific homebrew options
  options.hostbrew = {
    brews = lib.mkOption {
      type =
        with lib.types;
        listOf (coercedTo str (name: { inherit name; }) (submodule hostBrewOptionsFn));
      default = [ ];
      description = ''
        Set of host-specific homebrew brews packages
      '';
    };

    casks = lib.mkOption {
      type =
        with lib.types;
        listOf (coercedTo str (name: { inherit name; }) (submodule hostCaskOptionsFn));
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

    helpers = lib.mkOption {
      type = lib.types.raw;

      default = {
        restartApp = app: ''
          APPNAME=\"${app}\"
          pgrep -x \"$APPNAME\" > /dev/null || exit 0
          pkill -x \"$APPNAME\"
          count=0
          while pgrep -x \"$APPNAME\" > /dev/null && [ $count -lt 60 ]; do
            sleep 0.5
            count=$((count+1))
          done

          if pgrep -x \"$APPNAME\" > /dev/null; then
            pkill -9 -x \"$APPNAME\"
          fi

          open -a \"$APPNAME\"
        '';
      };
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
      postinstall = restartApp "WhatsApp";
    }
    {
      name = "signal";
      greedy = true;
      postinstall = restartApp "Signal";
    }
    {
      name = "google-drive";
      greedy = true;
      postinstall = restartApp "Google Drive";
    }
    {
      name = "logos";
      greedy = true;
      postinstall = restartApp "Logos";
    }
    {
      name = "microsoft-office";
      greedy = true;
    }
    {
      name = "zoom";
      greedy = true;
      postinstall = restartApp "zoom.us";
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
      postinstall = restartApp "Dropbox";
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
