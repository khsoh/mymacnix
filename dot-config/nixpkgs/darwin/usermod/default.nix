{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  isVM = osConfig.machineInfo.is_vm;
in
{
  imports = [
    ./github.nix
    ./gitlab.nix
    ./onepassword.nix
    ./sshkeys.nix
    ./terminal.nix
  ];

  ##### sshkeys configuration
  ## The locations of the SSH private and public key files
  # sshkeys.USERPKFILE = "${homeDir}/.ssh/id_ed25519";
  # sshkeys.USERPUBFILE = "${homeDir}/.ssh/id_ed25519.pub";
  # sshkeys.NIXIDPKFILE = "${homeDir}/.ssh/nixid_ed25519";
  # sshkeys.NIXIDPUBFILE = "${homeDir}/.ssh/nixid_ed25519.pub";

  #### Test the presence of SSH key files
  ### The configuration only builds if the following files exist:
  ## - nixid SSH private key file
  ## - nixid SSH public key file
  ## - user SSH public key file
  sshkeys.check_userpkfile = !isVM;
  sshkeys.check_userpubfile = !isVM;
  sshkeys.NIXIDPKOPLOC = lib.mkDefault "op://NIX Bootstrap/NIXID SSH Key";
  sshkeys.USERPKOPLOC = lib.mkDefault "op://Private/OPENSSH ED25519 Key";
  # sshkeys.check_userpubfile = true;
  # sshkeys.check_nixidpkfile = true;
  # sshkeys.check_nixidpubfile = true;

  ##### onepassword configuration
  onepassword.sshsign_pgm_present = !isVM;

  ##### github configuration
  # github.enable = true;   # Default
  # github.noreply_email is assigned to global config email if not specified

  ##### gitlab configuration
  # gitlab.enable = true;   # Default
  # gitlab.noreply_email is assigned to global config email if not specified

  #### terminal configuration
  terminal.package = if (!isVM) then pkgs.kitty else pkgs.ghostty-bin;
}
# vim: set ts=2 sw=2 et ft=nix:
