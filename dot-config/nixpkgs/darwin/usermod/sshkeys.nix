{ config, lib, ... }:
let
  homeDir = config.home.homeDirectory;
  sshcfg = config.sshkeys;

  read_pubkey =
    pubkeyfile:
    let
      # Read the file and strip the trailing newline
      content = lib.removeSuffix "\n" (builtins.readFile pubkeyfile);
      # Split by spaces into a list of strings
      parts = lib.splitString " " content;
    in
    # Take the first two elements and join them with a space
    builtins.concatStringsSep " " (lib.take 2 parts);
in
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
  # The options <*>file_present are readOnly flags to indicate whether
  # the specified key files are present.
  # The options check_<*>file are user flags to indicate whether
  # the specified key files must be present for the system to build
  # successfully.
  options.sshkeys = {

    USERPKFILE = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to current user's secret key file";
      default = "${homeDir}/.ssh/id_ed25519";
    };
    check_userpkfile = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    userpkfile_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    USERPKOPLOC = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Optional op:// location of user SSH key file";
      default = null;
    };

    USERPUBFILE = lib.mkOption {
      type = lib.types.path;
      description = "Relative path to current user's public key file";
      default = "${homeDir}/.ssh/id_ed25519.pub";
    };
    check_userpubfile = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    userpubfile_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    userssh_pubkey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
    };

    NIXIDPKFILE = lib.mkOption {
      type = lib.types.str;
      description = "Relative path to Nix system's secret key file";
      default = "${homeDir}/.ssh/nixid_ed25519";
    };
    check_nixidpkfile = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    nixidpkfile_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    NIXIDPKOPLOC = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Optional op:// location of Nix system's SSH key file";
      default = null;
    };

    NIXIDPUBFILE = lib.mkOption {
      type = lib.types.path;
      description = "Relative path to Nix system's public key file";
      default = "${homeDir}/.ssh/nixid_ed25519.pub";
    };
    check_nixidpubfile = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    nixidpubfile_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    nixidssh_pubkey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
    };
  };

  config.sshkeys = {
    userpkfile_present = builtins.pathExists sshcfg.USERPKFILE;
    userpubfile_present = builtins.pathExists sshcfg.USERPUBFILE;
    nixidpkfile_present = builtins.pathExists sshcfg.NIXIDPKFILE;
    nixidpubfile_present = builtins.pathExists sshcfg.NIXIDPUBFILE;

    userssh_pubkey = if sshcfg.userpubfile_present then (read_pubkey sshcfg.USERPUBFILE) else null;
    nixidssh_pubkey = if sshcfg.nixidpubfile_present then (read_pubkey sshcfg.NIXIDPUBFILE) else null;
  };

  ## Setup checks and asserts for the SSH private and public key files based on
  ## user configuration
  config.assertions = [
    {
      assertion = (!sshcfg.check_userpkfile) || (builtins.pathExists sshcfg.USERPKFILE);
      message = "The user ssh private key file ${sshcfg.USERPKFILE} is absent - this file must be present to build";
    }
    {
      assertion = (!sshcfg.check_userpubfile) || (builtins.pathExists sshcfg.USERPUBFILE);
      message = "The user ssh public key file ${sshcfg.USERPUBFILE} is absent - this file must be present to build";
    }
    {
      assertion = (!sshcfg.check_nixidpkfile) || (builtins.pathExists sshcfg.NIXIDPKFILE);
      message = "The NIXID ssh private key file ${sshcfg.NIXIDPKFILE} is absent - this file must be present to build";
    }
    {
      assertion = (!sshcfg.check_nixidpubfile) || (builtins.pathExists sshcfg.NIXIDPUBFILE);
      message = "The NIXID ssh public key file ${sshcfg.NIXIDPUBFILE} is absent - this file must be present to build";
    }
  ];
}
# vim: set ts=2 sw=2 et ft=nix:
