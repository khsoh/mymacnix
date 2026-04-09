{
  config,
  lib,
  ...
}:
let
  mkBeforePriority = (lib.mkBefore "").priority;
in
{
  imports = [
    ./dnssetup.nix
    ./nixAppsRegister.nix
    ./checkPinnedPkgs.nix
  ];

  # Setup ANSI terminal control variables - should appear before other postActivation.text
  system.activationScripts.postActivation.text = lib.mkOrder (mkBeforePriority - 50) ''
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
  '';
}
