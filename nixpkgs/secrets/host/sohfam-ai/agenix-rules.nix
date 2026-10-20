let
  pubkey = (import ./key.nix).pubkey;
  admin = (import ../../user/khsoh/key.nix).pubkey;
in
{
  "authentik-env.age" = {
    publicKeys = [
      admin
      pubkey
    ];
    armor = true;
  };
}
