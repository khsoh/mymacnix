{ config, ... }:
{
  imports = [
    ./sysopt
  ];
  ####  Configuration section ######
  ## Note that the commented out segments are the defaults - so these are not assigned
  # sysopt.USER = builtins.getEnv "USER";
  # sysopt.HOME = builtins.getEnv "HOME";
  # sysopt.NIXSYSPATH = "/run/current-system/sw/bin";

  # mod_gh.enable = true;
  mod_gh.noreply_email = "2169449+khsoh@users.noreply.github.com";

  ## The locations of the SSH private and public key files
  # mod_sshkeys.USERPKFILE = "${syscfg.HOME}/.ssh/id_ed25519";
  # mod_sshkeys.USERPUBFILE = "${syscfg.HOME}/.ssh/id_ed25519.pub";
  # mod_sshkeys.NIXIDPKFILE = "${syscfg.HOME}/.ssh/nixid_ed25519";
  # mod_sshkeys.NIXIDPUBFILE = "${syscfg.HOME}/.ssh/nixid_ed25519.pub";

  #### Test the presence of SSH key files
  ### The configuration only builds if the following files exist:
  ## - nixid SSH private key file
  ## - nixid SSH public key file
  ## - user SSH public key file
  mod_sshkeys.check_userpkfile = false;
  # mod_sshkeys.check_userpubfile = true;
  # mod_sshkeys.check_nixidpkfile = true;
  # mod_sshkeys.check_nixidpubfile = true;
  ####  End configuration section ######

}
