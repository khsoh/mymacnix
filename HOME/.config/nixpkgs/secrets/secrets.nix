let
  rxdev = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQt2ge9t4hjB+S06TUFIFjkaAdqRSx6gitM9rjCSBjl";
  users = [ rxdev ];
in {
  "config-private.age".publicKeys = users;
}
