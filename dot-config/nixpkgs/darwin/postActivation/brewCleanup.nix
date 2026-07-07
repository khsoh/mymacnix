{
  config,
  lib,
  ...
}:
{
  system.activationScripts.postActivation.text = lib.mkIf config.homebrew.enable (
    lib.mkAfter
      # bash
      ''
        # shellcheck disable=SC2059
        printf "''${GREEN}''${BOLD}======== Cleaning up homebrew ========''${ESC}\n"

        if [ -x "${config.homebrew.prefix}/bin/brew" ]; then
          sudo -i -u ${config.system.primaryUser} "${config.homebrew.prefix}/bin/brew" cleanup --prune=all
        fi

        # shellcheck disable=SC2059
        printf "''${BLUE}''${BOLD}==>''${ESC} Completed homebrew cleanup\n"
      ''
  );
}
