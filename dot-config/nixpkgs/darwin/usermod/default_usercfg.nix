{
  config,
  osConfig,
  pkgs,
  lib,
  user,
  ...
}:
let
  isVM = osConfig.machineInfo.is_vm;
  homeDir = config.home.homeDirectory;
in
{
  # User configuration settings for home-manager modules
  config = {
    ##### onepassword configuration
    # onepassword = {
    #    enable = lib.mkDefault (user.hasAppleID);
    #    SSHSIGN_PROGRAM = lib.mkDefault "${osConfig.helpers.getMacBundleAppName pkgs._1password-gui}/Contents/MacOS/op-ssh-sign";
    # };

    ##### github configuration
    # github = {
    #   enable = lib.mkDefault true;
    #   username = lib.mkDefault "khsoh";
    # };

    ##### gitlab configuration
    # gitlab = {
    #   enable = lib.mkDefault true;
    #   username = lib.mkDefault "khsoh";
    # };

    ##### terminal configuration
    # terminal.packages = [
    #   pkgs.ghostty-bin
    # ] ++ lib.optionals (!isVM) [
    #   pkgs.kitty
    # ];
  };
}
