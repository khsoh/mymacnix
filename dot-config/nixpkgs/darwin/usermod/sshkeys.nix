{ config, lib, ... }:
{
  ## SSH private and public keys for the user
  # It is possible to build system without a user private keyfile.
  # This is to build for systems running on a VM - so that the
  # chance of leaking the user private key is minimized
  # So, when running in VM, a default PKFILE is used

  ## Important - we must not use type lib.types.path in the options to
  # avoid the accidental copying of the secret key file to /nix/store
  # The paths to the SSH key files are specified as strings as absolute
  # paths
  #
  options.sshkeys = {
    PKFILE = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Absolute path to secret key file";
      default = null;
    };

    PUBFILE = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Relative path to public key file";
      default = null;
    };

    pubkey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = ''
        Public key string - this must be set if PUBFILE is null 
        (implying use of SSH_AUTH_SOCK to access keys)
      '';
      default = null;
    };
  };
}
# vim: set ts=2 sw=2 et ft=nix:
