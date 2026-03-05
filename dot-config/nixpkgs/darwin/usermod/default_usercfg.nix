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
    #     OPURI = lib.mkDefault "op://Private/OPENSSH ED25519 Key";
    #     pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBUfgkqOXhnONi4FAsFfZFeqW0Bkij6c/6zJf8Il1oCX";
    #   })
    #   (lib.mkIf (!config.onepassword.enable) {
    #     OPURI = lib.mkDefault "op://NIX Bootstrap/NIXID SSH Key";
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
