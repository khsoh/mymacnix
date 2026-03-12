let
  pkinfo = (import ./default.nix { });

  # Create logical groups for easy use in the 'in' block
  allHosts = builtins.attrValues pkinfo.hosts.content;
  allUsers = builtins.attrValues pkinfo.users.content;

  # Relative paths for host and user
  hostDir = "host/${pkinfo.pkhost.agecfg.name}";
  userDir = "user/${pkinfo.pkuser.agecfg.name}";

  # Define current host and current user secrets.nix
  hostSecrets = ./. + "/${hostDir}/secrets.nix";
  userSecrets = ./. + "/${userDir}/secrets.nix";

  # Helper to prefix attribute names with their subdirectory
  prefixSecrets =
    dir: secrets:
    builtins.listToAttrs (
      map (name: {
        name = "${dir}/${name}";
        value = secrets.${name};
      }) (builtins.attrNames secrets)
    );

  # Helper to import if path exists, otherwise return an empty set
  importIfExists = path: if builtins.pathExists path then import path else { };

  rawHostSecrets = importIfExists hostSecrets;
  rawUserSecrets = importIfExists userSecrets;
in
{
  "mac-raise2.json.age" = {
    publicKeys = map (x: x.agecfg.pubkey) (allHosts ++ allUsers);
    armor = true;
  };
}
## Add the host-specific and user-specific secrets to re-key all at one go.
// (prefixSecrets hostDir rawHostSecrets)
// (prefixSecrets userDir rawUserSecrets)

# vim: set ts=2 sw=2 et ft=nix:
