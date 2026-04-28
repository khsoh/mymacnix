{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Shortcut to get helper functions
  Helpers = config.helpers;

  idNameMap = builtins.attrValues (
    builtins.mapAttrs (name: id: "${toString id}|${name}") config.homebrew.masApps
  );
  idNameMapStr = builtins.concatStringsSep "\n" idNameMap;
in
{
  system.activationScripts.preActivation.text = ''
    MAS=/opt/homebrew/bin/mas
    TARGET_FILE="/tmp/masapps_upgrades"
    : > "$TARGET_FILE"
    chown ${config.system.primaryUser} "$TARGET_FILE"

    OUTDATED_IDS=$(sudo -u ${config.system.primaryUser} $MAS outdated | awk '{print $1}')

    echo "${idNameMapStr}" | while IFS="|" read -r MAP_ID MAP_NAME; do
      for ID in $OUTDATED_IDS; do
        if [ "$ID" == "$MAP_ID" ]; then
          ENTRY="\"$MAP_NAME\"=$MAP_ID"
          echo "$ENTRY" >> "$TARGET_FILE"
          echo "Homebrew mas app update: $ENTRY"
        fi
      done
    done
  '';
}
