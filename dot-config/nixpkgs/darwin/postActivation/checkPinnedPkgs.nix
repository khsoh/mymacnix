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
      revisionFile = stdPkgsPath + "/.git-revision";
      currentNixpkgsRev =
        if builtins.pathExists revisionFile then builtins.readFile revisionFile else "unknown";

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

      excludeCurrentRev =
        pkg:
        !(pkg ? ignoredCommits)
        || (builtins.all (pre: !(lib.hasPrefix pre currentNixpkgsRev)) pkg.ignoredCommits);
      externalPkgs = builtins.filter isExternal config.environment.systemPackages;
      untestedPkgs = builtins.filter excludeCurrentRev externalPkgs;
      names = builtins.concatStringsSep "\n\${BLUE}\${BOLD}>>\${ESC} " (
        map (p: p.pname or (lib.getName p)) untestedPkgs
      );
    in
    lib.mkIf (untestedPkgs != [ ]) (
      lib.mkAfter ''
        # shellcheck disable=SC2059
        printf "''${RED}''${BOLD}======== Packages NOT YET tested with main nixpkgs (${currentNixpkgsRev}) ========''${ESC}\n"
        # shellcheck disable=SC2059
        printf "''${RED}''${BOLD}>>''${ESC} ${names}\n"
        # shellcheck disable=SC2059
        printf "''${RED}''${BOLD}==>''${ESC} Consider testing these packages with latest nixpkgs revision.\n"
      ''
    );
}
