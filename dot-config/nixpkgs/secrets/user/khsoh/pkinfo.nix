let
  userInfo = import <darwin-config/userinfo.nix>;
in
{
  OPURI = "op://Private/Personal age private key";
  pubkey = "age1wl5azg6umw6uevcwwxvmjszf3unrh6huj8xcwaupxyatrr75dfuq6x636s";
  PKFILE = "${userInfo.home}/.age/key.txt";
  PUBFILE = "${userInfo.home}/.age/public.txt";
}
