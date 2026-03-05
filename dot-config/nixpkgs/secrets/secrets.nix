let
  pkinfo = import ./getpkinfo.nix;

  # Create logical groups for easy use in the 'in' block
  allHosts = builtins.attrValues pkinfo.hosts;
  allUsers = builtins.attrValues pkinfo.users;
in
{
  "mac-raise2.json.age" = {
    publicKeys = map (x: x.pubkey) (allHosts ++ allUsers);
    armor = true;
  };
}
# vim: set ts=2 sw=2 et ft=nix:
