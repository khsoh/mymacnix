{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Shortcut to get helper functions
  Helpers = config.helpers;
in
{
  system.activationScripts.postActivation.text = lib.mkBefore ''
    # shellcheck disable=SC2034
    ESC="\x1b[0m"
    # shellcheck disable=SC2034
    BOLD="\x1b[1m"
    # shellcheck disable=SC2034
    RED="\x1b[31m"
    # shellcheck disable=SC2034
    GREEN="\x1b[32m"
    # shellcheck disable=SC2034
    YELLOW="\x1b[33m"
    # shellcheck disable=SC2034
    BLUE="\x1b[34m"
    # shellcheck disable=SC2059
    printf "''${GREEN}''${BOLD}======== nixpkgs Apps re-registration ========''${ESC}\n"
    PRINT_HEADER=1

    # 1. Map previous binaries to their store paths
    # We use 'find' to safely resolve every symlink in the old bin directory.
    # Result format: "package-name:/nix/store/hash-package-name"
    PREV_MAP=""
    if [ -d "/run/current-system/Applications/" ]; then
      while IFS= read -r app_path; do
        target=$(readlink -f "$app_path")

        # Extract the package name (the part after the hash)
        pkg_name=$(basename "$target")

        # Modify target to get only the one in /nix/store
        target=''${target%/Applications/*}
        # Store as "name:path" for easy lookup
        PREV_MAP="$PREV_MAP$pkg_name:$target"$'\n'
      done < <(find /run/current-system/Applications/ -maxdepth 1 -type l)
    fi

    LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

    # --- Check each package in the new configuration
    ${lib.concatMapStringsSep "\n" (
      pkg:
      let
        pkgName = pkg.pname or (builtins.parseDrvName pkg.name).name;
        appName = Helpers.getMacAppName pkg;
        newPath = "${pkg}";
      in
      ''
        NEW_PATH="${newPath}"
        APP_NAME="${appName}"
        PKG_NAME="${pkgName}"

        # Find the old path by looking for the package name in our map
        OLD_PATH=$(echo "$PREV_MAP" | grep "^$APP_NAME:" || : | cut -d: -f2- | head -n 1)

        if [[ $PRINT_HEADER -eq 1 && "$OLD_PATH" != "$NEW_PATH" ]]; then
          # shellcheck disable=SC2059
          printf "\n''${BLUE}''${BOLD}--- Modified or New Mac Applications ---''${ESC}\n"
          PRINT_HEADER=0
        fi


        if [ -z "$OLD_PATH" ]; then
          # shellcheck disable=SC2059
          printf "''${RED}[New]''${ESC} %s\n" "$APP_NAME - $PKG_NAME"
          echo "  └─ $NEW_PATH"
        elif [ "$OLD_PATH" != "$NEW_PATH" ]; then
          # shellcheck disable=SC2059
          printf "''${RED}[Modified]''${ESC} %s\n" "$APP_NAME - $PKG_NAME"
          echo "  └─ OLD: $OLD_PATH"
          echo "  └─ NEW: $NEW_PATH"
        fi

        if [[ "$OLD_PATH" != "$NEW_PATH" && -d "/Applications/Nix Apps/$APP_NAME" ]]; then
          # Reset permissions for kitty
          if [[ "$APP_NAME" == "kitty.app" ]]; then
            tccutil reset Accessibility "$(mdls -name kMDItemCFBundleIdentifier -raw "/Applications/Nix Apps/$APP_NAME")"
          fi

          # --- Fix macOS Launch Services for Nix Apps ---
          # This forces macOS to recognize the app bundle immediately after rebuild
          echo "Registering $APP_NAME in /Applications/Nix Apps with Launch Services..."
          $LSREGISTER -f "/Applications/Nix Apps/$APP_NAME"
        fi
      ''
    ) (lib.filter (p: Helpers.getMacAppName p != "") config.environment.systemPackages)}
    # shellcheck disable=SC2059
    printf "''${BLUE}''${BOLD}==>''${ESC} Completed nixpkgs Apps re-registration\n"
  '';
}
