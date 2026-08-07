{
  config,
  pkgs,
  lib,
  ...
}:
builtins.seq [ pkgs ] {
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
          LATESTREV=$(curl -sIL --connect-timeout 20 \
            --retry 3 \
            --retry-delay 10 \
            --retry-connrefused \
            -o /dev/null -w '%{url_effective}' "$(nix-channel --list | awk '/^nixpkgs / { print $2 }')" | sed -e 's/.*[\./]//')
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
