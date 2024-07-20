let
  pubkeys = import ./pubkeys.nix;
in {
  "config-private.age".publicKeys = pubkeys;
}
