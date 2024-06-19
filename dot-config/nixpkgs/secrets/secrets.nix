let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
  usersys = import ../darwin/usersys.nix { inherit lib; };

  user = usersys.ssh_user_pubkey;
  rxdev = usersys.nixid_pubkey;
  users = [ user rxdev ];
in {
  "config-private.age".publicKeys = users;
}
