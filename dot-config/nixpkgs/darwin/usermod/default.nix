{ lib, ... }:
{
  imports = [
    ./github.nix
    ./gitlab.nix
    ./onepassword.nix
    ./sshkeys.nix
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
  sshkeys.check_userpkfile = false;
  # sshkeys.check_userpubfile = true;
  # sshkeys.check_nixidpkfile = true;
  # sshkeys.check_nixidpubfile = true;

  ##### github configuration
  # github.enable = true;   # Default
  # github.noreply_email = "2169449+khsoh@users.noreply.github.com";
  github.noreply_email = "hju37823@outlook.com";

  ##### gitlab configuration
  # gitlab.enable = true;   # Default
  # gitlab.noreply_email = "22681633-khsoh@users.noreply.gitlab.com";
  gitlab.noreply_email = "hju37823@outlook.com";
}
