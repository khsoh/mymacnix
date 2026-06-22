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
            printf "''${GREEN}''${BOLD}======== Private Host Mappings ========''${ESC}\n"

            # Nix will automatically evaluate this to your user's specific runtime path
            SECRET_PATH="${userHostsPath}"

            if [ -f "$SECRET_PATH" ]; then
              START_MARKER="# --- START AGENIX HOSTS ---"
              END_MARKER="# --- END AGENIX HOSTS ---"

              # Root cleans out the old markers from /etc/hosts
              sed -i "" "/$START_MARKER/,/$END_MARKER/d" /etc/hosts

              # Root reads your user-owned secret and appends it to /etc/hosts
              {
                echo "$START_MARKER"
                cat "$SECRET_PATH"
                echo "$END_MARKER"
              } >> /etc/hosts
            fi
            # shellcheck disable=SC2059
            printf "''${BLUE}''${BOLD}==>''${ESC} Completed Private Host Mappings\n"
          ''
      );
}
