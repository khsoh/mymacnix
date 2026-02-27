{ lib, config, ... }:
let
  getBrewName = item: if builtins.isAttrs item then item.name else item;
in
{
  options.globals = {
    nixAppsPath = lib.mkOption {
      type = lib.types.str;
      default = "/Applications/Nix Apps";
    };
  };

  options.helpers = lib.mkOption {
    type = lib.types.raw;

    default = {
      ## Function to get the Mac App Name
      # E.g. "abc.app".
      # It will return "" if not name is found
      getMacAppName =
        pkg:
        let
          appsDir = "${pkg}/Applications";
          contents = if builtins.pathExists appsDir then builtins.readDir appsDir else { };
          appNames = lib.filter (n: builtins.match ".*\\.app$" n != null) (builtins.attrNames contents);
        in
        if appNames == [ ] then "" else builtins.head appNames;

      ## Function to generate the path of the Mac App Bundle name from the nix package
      # E.g. "/Applications/Nix Apps/abc.app".
      # It will return an empty string "" if no Mac App Bundle name is found.
      getMacBundleAppName =
        pkg:
        let
          appName = config.helpers.getMacAppName pkg;
        in
        lib.optionalString (appName != "") "${config.globals.nixAppsPath}/${appName}";

      ## Checks if package is installed within environment.system.packages
      pkgInstalled =
        pkg:
        let
          # Safely get the lists, defaulting to empty lists if they don't exist
          systemPkgs = config.environment.systemPackages or [ ];

          # helper to get package name for more reliable matching
          getName = p: p.pname or (builtins.parseDrvName p.name).name or "";
          targetName = getName pkg;
        in
        builtins.any (p: (getName p) == targetName) systemPkgs;

      ## Test if app is installed as a homebrew package
      brewAppInstalled =
        name:
        (builtins.any (x: getBrewName x == name) config.homebrew.brews)
        # Check formulae
        || (builtins.any (x: getBrewName x == name) config.homebrew.casks)
        # Check casks
        || (builtins.hasAttr name config.homebrew.masApps); # Check Mac App Store apps
    };

  };
}
