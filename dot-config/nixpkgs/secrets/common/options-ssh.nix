{
  config,
  lib,
  ...
}:
{
  ## SSH private and public keys for the host/user

  ## Important - we must not use type lib.types.path in the options to
  # avoid the accidental copying of the secret key file to /nix/store
  # The paths to the SSH key files are specified as strings as absolute
  # paths
  #
  options.sshcfg = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.submodule {
        options = {
          OPURI = lib.mkOption {
            type = lib.types.str;
            description = "1Password URI reference to SSH key. Only includes the Vault and Item (without the field)";
          };
          PKFILE = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "Path to SSH private key. Can be null if private key is accessed via SSH_AUTH_SOCK";
            default = null;
          };
          PUBFILE = lib.mkOption {
            type = lib.types.str;
            description = "Path to SSH public key.";
          };

          ###  Important note: This pubkey must be assigned because agenix needs the key to embed in
          # secrets.nix
          pubkey = lib.mkOption {
            type = lib.types.str;
            description = "Public key string - this attribute must be set if sshcfg is not null";
          };
        };
      }
    );
    default = null;
    description = "SSH key configuration";
  };
}
