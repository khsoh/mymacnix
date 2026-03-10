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
    ##### sshkeys configuration
    # sshkeys = lib.mkMerge [
    #   (lib.mkIf config.onepassword.enable {
    #     pubkey = lib.mkDefault (
    #       if ((sshcfg.PUBFILE != null) && (builtins.pathExists sshcfg.PUBFILE)) then
    #         (readPubkey sshcfg.PUBFILE)
    #       else
    #         null
    #     );
    #   })
    #   (lib.mkIf (!config.onepassword.enable) {
    #     PKFILE = lib.mkDefault "${homeDir}/.ssh/nixid_ed25519";
    #     PUBFILE = lib.mkDefault "${homeDir}/.ssh/nixid_ed25519.pub";
    #
    #     # Read from PUBFILE if it exists
    #     pubkey = lib.mkDefault (if (sshcfg.PUBFILE != null) then (readPubkey sshcfg.PUBFILE) else null);
    #   })
    # ];

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
