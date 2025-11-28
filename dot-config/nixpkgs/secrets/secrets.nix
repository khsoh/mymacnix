let
  pubkeys = import ./pubkeys.nix;
in {
  "armored-secrets.json.age" = {
    publicKeys = pubkeys;
    armor = true;
  };
}
