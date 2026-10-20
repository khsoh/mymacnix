let
  pubkey = (import ./key.nix).pubkey;
in
{
  "secrets.json.age" = {
    publicKeys = [ pubkey ];
    armor = true;
  };
}
