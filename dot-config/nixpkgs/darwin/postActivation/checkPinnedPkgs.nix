{
  config,
  pkgs,
  lib,
  ...
}:
let
  ## Store paths of packages installed by environment.systemPackages
  stdPkgsPath = toString pkgs.path;
  darwinPath = toString <darwin>;
  agenixPath = toString <agenix>;
in
{
  system.activationScripts.postActivation.text =
    let
      # Filter for packages whose source nixpkgs path is non-standard
      isExternal =
        pkg:
        let
          pkgPath = pkg.meta.position or "";
        in
        !(
          (lib.hasPrefix stdPkgsPath pkgPath)
          || (lib.hasPrefix darwinPath pkgPath)
          || (lib.hasPrefix agenixPath pkgPath)
        );

      externalPkgs = builtins.filter isExternal config.environment.systemPackages;
      names = builtins.concatStringsSep "\n\${BLUE}\${BOLD}>>\${ESC} " (
        map (p: p.pname or (lib.getName p)) externalPkgs
      );
    in
    lib.mkIf (externalPkgs != [ ]) (
      lib.mkAfter ''
        # shellcheck disable=SC2059
        printf "''${GREEN}''${BOLD}======== Packages NOT from main nixpkgs ========''${ESC}\n"
        # shellcheck disable=SC2059
        printf "''${BLUE}''${BOLD}>>''${ESC} ${names}\n"
        # shellcheck disable=SC2059
        printf "''${BLUE}''${BOLD}==>''${ESC} Consider if these packages still require pins.\n"
      ''
    );
}
