let
  # 1. Define pinned sources there
  # You can have different URLs/commits for different packages
  # You can comment out everything within sources if there is nothing to override
  sources = {
    "bitwarden-desktop" = {
      # url = "https://github.com/NixOS/nixpkgs/archive/d99b013d5d19.tar.gz";
      url = <nixpkgs>; # Use the latest version - will add in permittedInsecurePackages attribute
      ignoredCommits = [
        "8c91a71d1345"
        "173d0ad7a974"
        "49a4bd0573c3"
        "5a722a7155bf"
      ];
      # Optional: Add a description or version tag for clarity
      desc = "Modified bitwarden-desktop to support EOL electron";
      # Override with EOL electron version
      permittedInsecurePackages = [ "electron-39.8.10" ];
    };

    # "bitwarden-desktop" = {
    #   url = "https://github.com/NixOS/nixpkgs/archive/d99b013d5d19.tar.gz";
    #   ignoredCommits = [
    #     "8c91a71d1345"
    #     # "173d0ad7a974"
    #     # "49a4bd0573c3"
    #   ];
    #   # Optional: Add a description or version tag for clarity
    #   desc = "Modified bitwarden-desktop to support EOL electron";
    # };
    # zsh = {
    #   url = "https://github.com/NixOS/nixpkgs/archive/b86751bc4085.tar.gz";
    #   ignoredCommits = [
    #     "01fbdeef22b7"
    #     "6368eda62c97"
    #   ];
    #   # Optional: Add a description or version tag for clarity
    #   desc = "Pinned ZSH (commit b86751bc)";
    # };

    # Example of a second package with a DIFFERENT pin
    # firefox = {
    #   url = "https://github.com/NixOS/nixpkgs/archive/some-other-commit.tar.gz";
    #   ignoredCommits = [ "01fbdeef22b7" "6368eda62c97" ];
    #   desc = "Pinned Firefox";
    # };
  };

  # 2. Helper function to create the override logic for a single package
  # This takes the package name, the source config, and the original package
  mkOverride =
    pkgName: srcConfig: prev:
    let
      # Filter out 'rewriteURL' if it is null to stop nixpkgs from crashing
      baseConfig =
        if prev.config ? rewriteURL && prev.config.rewriteURL == null then
          removeAttrs prev.config [ "rewriteURL" ]
        else
          prev.config;

      # Inject the local package exceptions into the config block if they exist
      safeConfig =
        baseConfig
        // (
          if srcConfig ? permittedInsecurePackages then
            {
              permittedInsecurePackages =
                (baseConfig.permittedInsecurePackages or [ ]) ++ srcConfig.permittedInsecurePackages;
            }
          else
            { }
        );

      nixpkgsSource =
        if builtins.isPath srcConfig.url then srcConfig.url else fetchTarball { url = srcConfig.url; };

      # Import the pinned version for this specific source
      # Pass prev.config to the imported nixpkgs instance to respect
      # any package that enable allowUnfreePredicate.
      pinnedPkgs = import nixpkgsSource {
        # inherit (prev) config;
        config = safeConfig;
        system = prev.stdenv.hostPlatform.system;
      };
      pinnedPkg = pinnedPkgs.${pkgName};

      # Get the original package from the current channel (prev)
      originalPkg = prev.${pkgName};

      # Ensure passthru exists
      existingPassthru = originalPkg.passthru or { };
    in
    # Apply the override
    pinnedPkg.overrideAttrs (old: {
      passthru = existingPassthru // {
        ignoredCommits = srcConfig.ignoredCommits;
      };
    });

  # 3. Construct the final overlay function
  # We iterate over our sources map and build the attribute set
  overlayFn =
    final: prev:
    builtins.listToAttrs (
      map (pkgName: {
        name = pkgName;
        value = mkOverride pkgName sources.${pkgName} prev;
      }) (builtins.attrNames sources)
    );
in
[ overlayFn ]
