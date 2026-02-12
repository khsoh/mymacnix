let
  pubkeys = import ./pubkeys.nix;
in
{
  "armored-secrets.json.age" = {
    publicKeys = pubkeys;
    armor = true;
  };
  "mac-raise2.json.age" = {
    publicKeys = pubkeys;
    armor = true;
  };
}
# vim: set ts=2 sw=2 et ft=nix:
