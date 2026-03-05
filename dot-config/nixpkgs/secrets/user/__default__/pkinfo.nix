let
  userInfo = import <darwin-config/userinfo.nix>;
in
{
  OPURI = "op://Nix Bootstrap/NIXID age private key";
  pubkey = "age1rsuacwv646wtd53kj7j5af5xqjxjw7wtuv33vejr2rgfvvxjufasx32zql";
  PKFILE = "${userInfo.home}/.age/nixid_key.txt";
  PUBFILE = "${userInfo.home}/.age/nixid_public.txt";
}
