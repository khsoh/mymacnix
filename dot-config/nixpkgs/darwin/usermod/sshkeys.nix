{ config, lib, ... }:
{
  ## SSH private and public keys for the user and Nix
  # It is possible to build system without a user private keyfile.
  # This is to build for systems running on a VM - so that the
  # chance of leaking the user private key is minimized
  # So, when running in VM, the USERPKFILE need not be present

  ## Important - we must not use type lib.types.path in the options to
  # avoid the accidental copying of the secret key file to /nix/store
  # The paths to the SSH key files are specified as strings as absolute
  # paths
  #
  # The options check_<*>file are user flags to indicate whether
  # the specified key files must be present for the system to build
  # successfully.
  options.sshkeys = lib.mkOption {
    description = "Describe SSH Public Key infrastructure";
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          OPURI = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "Optional 1Password CLI op:// URI of SSH Private Key";
            default = null;
          };

          PKFILE = lib.mkOption {
            type = lib.types.str;
            description = "Absolute path to secret key file";
          };

          PUBFILE = lib.mkOption {
            type = lib.types.str;
            description = "Relative path to public key file";
          };
        };
      }
    );
  };
}
# vim: set ts=2 sw=2 et ft=nix:
