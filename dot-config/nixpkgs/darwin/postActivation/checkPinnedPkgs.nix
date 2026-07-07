{
  config,
  pkgs,
  lib,
  ...
}:
let
  ## Store paths of packages installed by environment.systemPackages
  stdPkgsPath = toString pkgs.path;
in
{
  system.activationScripts.postActivation.text =
    let
      # Filter for packages that have overlays
      isOverlaidPkg = pkg: pkg ? ignoredCommits;

      overlaidPkgs = builtins.filter isOverlaidPkg config.environment.systemPackages;
    in
    lib.mkIf (overlaidPkgs != [ ]) (
      lib.mkAfter (
        # bash
        ''
          LATESTREV=$(curl -LIs -o /dev/null -w '%{url_effective}' "$(nix-channel --list | awk '/^nixpkgs-latest / { print $2 }')" | sed -e 's/.*[\./]//')
          LATESTREV="''${LATESTREV:0:12}"
        ''
        + builtins.concatStringsSep "\n" (
          map (
            p:
            # bash
            ''
              # shellcheck disable=SC2034
              IGNOREDCOMMITS=(${builtins.concatStringsSep " " (map (x: "\"${x}\"") p.ignoredCommits)})

              FOUND=false
              for commit in "''${IGNOREDCOMMITS[@]}"; do
                if [ "$commit" = "$LATESTREV" ]; then
                  FOUND=true
                  break
                fi
              done

              if [ "$FOUND" = false ]; then
                # shellcheck disable=SC2059
                printf "''${RED}''${BOLD}======== ${p.pname or (lib.getName p)} NOT YET tested with latest nixpkgs ($LATESTREV) ========''${ESC}\n"
                # shellcheck disable=SC2059
                printf "''${RED}''${BOLD}==>''${ESC} Consider testing package with latest nixpkgs revision.\n"
              fi
            '') overlaidPkgs
        )
      )
    );
}
