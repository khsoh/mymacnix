let
  pubkey = (import ./key.nix).pubkey;
in
{
  "iMessageID.json.age" = {
    publicKeys = [ pubkey ];
    armor = true;
  };
}
