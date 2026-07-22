{
  osConfig,
  config,
  options,
  pkgs,
  lib,
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
builtins.seq [ osConfig pkgs ] {
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

    # masApps will be moved to programs.mas.packages
    masApps = lib.mkOption {
      type = options.homebrew.masApps.type;
      default = { };
      description = ''
        Set of host-specific homebrew masApps packages
      '';
    };

    helpers = lib.mkOption {
      type = lib.types.raw;

      default = {
        restartApp = app: ''
          ${../../darwin/jxa/reqCloseApp.js} \"${app}\"
        '';
        restartApp2 = appName: procName: ''
          ${../../darwin/jxa/reqCloseApp.js} \"${appName}\" \"${procName}\"
        '';
      };
    };
  };

  config.hostbrew.brews = lib.mkBefore [
    "exercism"
  ];

  config.hostbrew.casks = lib.mkBefore [
    {
      name = "whatsapp";
      greedy = true;
    }
    {
      name = "signal";
      greedy = true;
      postinstall = restartApp "Signal";
    }
    {
      name = "keet";
      greedy = true;
    }
    {
      name = "google-drive";
      greedy = true;
    }
    {
      name = "google-chrome";
      greedy = true;
      postinstall = restartApp "Google Chrome";
    }
    {
      name = "brave-browser";
      greedy = true;
      postinstall = restartApp "Brave Browser";
    }
    {
      name = "proton-drive";
      greedy = true;
      postinstall = restartApp "Proton Drive";
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
  ];
}
# vim: set ts=2 sw=2 et ft=nix:
