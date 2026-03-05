let
  pubkey = (import ./pkinfo.nix).pubkey;
in
{
  "secrets.json.age" = {
    publicKeys = [ pubkey ];
    armor = true;
  };
}
