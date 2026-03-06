let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  currentUser = (import <darwin-config/userinfo.nix>).name;
  currentHost = (import "/etc/nix-darwin/machine-info.nix").hostname;

  # Helper: List all directories in a path
  getDirs =
    path:
    builtins.attrNames (lib.filterAttrs (name: type: type == "directory") (builtins.readDir path));

  # Helper: Import pkinfo.nix from each discovered directory
  # Returns an attribute set like: { macbook = { OPURI = "op://..."; pubkey = "age1..."; }; }
  importKeys =
    path:
    builtins.listToAttrs (
      map (name: {
        name = name;
        value = import (path + "/${name}/pkinfo.nix") // {
          name = name;
        };
      }) (getDirs path)
    );

  # Crawl the folders
  users = importKeys ./user;
  hosts = importKeys ./host;

  # Get the matching host/user pk info
  pkhost = hosts."${currentHost}" or hosts.__default__;
  pkuser = users."${pkhost.users."${currentUser}" or pkhost.users.__default__}";
in
{
  users = users;
  hosts = hosts;

  ## These are the key data for current host and current user
  pkhost = pkhost;
  pkuser = pkuser;
}
# vim: set ts=2 sw=2 et ft=nix:
