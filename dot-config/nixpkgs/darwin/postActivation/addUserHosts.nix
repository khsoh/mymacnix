{
  config,
  pkgs,
  lib,
  ...
}:
let
  userHostsPath = lib.attrByPath [
    "home-manager"
    "users"
    config.system.primaryUser
    "age"
    "secrets"
    "custom-hosts"
    "path"
  ] null config;
in
{
  system.activationScripts.postActivation.text =
    lib.mkIf (userHostsPath != null && builtins.pathExists userHostsPath)
      (
        lib.mkAfter
          # bash
          ''
            # shellcheck disable=SC2059
            printf "''${GREEN}''${BOLD}======== User Host Mappings ========''${ESC}\n"

            # Nix will automatically evaluate this to your user's specific runtime path
            SECRET_PATH="${userHostsPath}"

            START_MARKER="# --- START AGENIX HOSTS ---"
            END_MARKER="# --- END AGENIX HOSTS ---"

            # Create the new block
            NEW_BLOCK="$START_MARKER"$'\n'
            [ -f "$SECRET_PATH" ] && NEW_BLOCK+=$(cat "$SECRET_PATH")$'\n' || true
            NEW_BLOCK+="$END_MARKER"

            # Extract the existing block and strip its blank lines
            CURRENT_BLOCK=$(sed -n "/$START_MARKER/,/$END_MARKER/p" /etc/hosts | grep -v "^\s*$")

            # Only edit /etc/hosts if the contents do not match
            if [ "$NEW_BLOCK" != "$CURRENT_BLOCK" ]; then
              # shellcheck disable=SC2059
              printf "''${RED}''${BOLD}==>''${ESC} Modifying /etc/hosts file with user host mappings\n"

              # Root cleans out the old markers from /etc/hosts
              sed -i "" "/$START_MARKER/,/$END_MARKER/d" /etc/hosts

              # Add in the new block
              echo "$NEW_BLOCK" >> /etc/hosts
            fi

            # shellcheck disable=SC2059
            printf "''${BLUE}''${BOLD}==>''${ESC} Completed User Host Mappings\n"
          ''
      );
}
