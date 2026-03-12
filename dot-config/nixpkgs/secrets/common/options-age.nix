{ config, lib, ... }:
{
  options.agecfg = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "This should be the name of folder within <darwin-secret>/(host|user)/ this config is in";
    };
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
      description = "AGE public key string - must be assigned by you (not read from PUBFILE in nix)";
    };
  };
}
