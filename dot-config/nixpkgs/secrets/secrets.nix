let
  pkgs = import <nixpkgs> {};
  sshcfg = (pkgs.lib.evalModules {
    modules = [
      ./../darwin/sysopt
      ./../darwin/cfg.nix
    ];
  }).config.mod_sshkeys;

  user = sshcfg.userssh_pubkey;
  rxdev = sshcfg.nixidssh_pubkey;
  users = [ user rxdev ];
in {
  "config-private.age".publicKeys = users;
}
