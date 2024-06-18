{
  USER = builtins.getEnv "USER";
  HOME = builtins.getEnv "HOME";
  NIXSYSPATH = "/run/current-system/sw/bin";

  # github no reply email
  gh_noreply_email = "2169449+khsoh@users.noreply.github.com";

  # SSH public keys - nixid_pubkey is used for testing in my VM environment
  #   - this is useful for testing in case we accidentally leak SSH key from test environment
  ssh_user_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBUfgkqOXhnONi4FAsFfZFeqW0Bkij6c/6zJf8Il1oCX";
  nixid_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQt2ge9t4hjB+S06TUFIFjkaAdqRSx6gitM9rjCSBjl";
}
