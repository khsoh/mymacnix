{
  config,
  osConfig,
  pkgs,
  lib,
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
    # config.sshkeys = {
    #   ## The locations of the SSH private and public key files
    #   USERPKFILE = lib.mkDefault "${homeDir}/.ssh/id_ed25519";
    #   USERPUBFILE = lib.mkDefault "${homeDir}/.ssh/id_ed25519.pub";
    #   NIXIDPKFILE = lib.mkDefault "${homeDir}/.ssh/nixid_ed25519";
    #   NIXIDPUBFILE = lib.mkDefault "${homeDir}/.ssh/nixid_ed25519.pub";
    #
    #   #### Test the presence of SSH key files
    #   ### The configuration only builds if the following files exist:
    #   ## - nixid SSH private key file
    #   ## - nixid SSH public key file
    #   check_nixidpkfile = lib.mkDefault true;
    #   check_nixidpubfile = lib.mkDefault true;
    #   check_userpkfile = lib.mkDefault (!isVM);
    #   check_userpubfile = lib.mkDefault (!isVM);
    #
    #   ## 1Password CLI op URL to SSH keys
    #   NIXIDPKOPLOC = lib.mkDefault "op://NIX Bootstrap/NIXID SSH Key";
    #   USERPKOPLOC = lib.mkDefault "op://Private/OPENSSH ED25519 Key";
    # };

    ##### onepassword configuration
    # onepassword = {
    #   sshsign_pgm_present = lib.mkDefault (!isVM);
    #   SSHSIGN_PROGRAM = lib.mkDefault "/Applications/Nix Apps/1Password.app/Contents/MacOS/op-ssh-sign";
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
