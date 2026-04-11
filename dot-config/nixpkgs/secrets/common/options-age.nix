{
  lib,
  name,
  cfgdir,
  ...
}:
let
  ageOptions =
    { config, ... }:
    {
      options = {
        OPURI = lib.mkOption {
          type = lib.types.str;
          description = "1Password URI secret reference to AGE secret key";
        };
        PKFILE = lib.mkOption {
          type = lib.types.str;
          description = "Path to AGE secret key";
        };
        PUBFILE = lib.mkOption {
          type = lib.types.str;
          description = "Path to AGE public key";
        };

        ###  Important note: This pubkey must be assigned because agenix needs the key to embed in
        # secrets.nix
        pubkey = lib.mkOption {
          type = lib.types.str;
          description = "AGE public key string - will be read from key.nix";
          readOnly = true;
        };
      };

      config = {
        pubkey = (import "${cfgdir}/${name}/key.nix").pubkey;
      };
    };
in
{
  options.agecfg = lib.mkOption {
    type = lib.types.submodule ageOptions;
    description = "Agenix configuration";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
