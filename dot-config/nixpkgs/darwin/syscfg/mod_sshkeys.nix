{ config, lib, ... }:
let
  sshcfg = config.mod_sshkeys;
in {

  ## SSH private and public keys for the user and Nix
  # It is possible to build system without a user private keyfile.
  # This is to build for systems running on a VM - so that the
  # chance of leaking the user private key is minimized
  # So, when running in VM, the USERPKFILE need not be present

  ## Important - we must not use lib.types.path - otherwise the file
  # may be copied to /nix/store
  # Paths are relative to HOME folder
  # Note also that the options that are lowercase are readOnly
  # And these are setup in this file
  options.mod_sshkeys = {

    USERPKFILE = lib.mkOption {
      type = lib.types.str;
      description = "Relative path to current user's secret key file";
      default = "${config.syscfg.HOME}/.ssh/id_ed25519";
    };
    userpkfile_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };

    USERPUBFILE = lib.mkOption {
      type = lib.types.path;
      description = "Relative path to current user's public key file";
      default = "${config.syscfg.HOME}/.ssh/id_ed25519.pub";
    };
    userpubfile_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    userssh_pubkey = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
    };

    NIXIDPKFILE = lib.mkOption {
      type = lib.types.str;
      description = "Relative path to Nix system's secret key file";
      default = "${config.syscfg.HOME}/.ssh/nixid_ed25519";
    };
    nixidpkfile_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };

    NIXIDPUBFILE = lib.mkOption {
      type = lib.types.path;
      description = "Relative path to Nix system's public key file";
      default = "${config.syscfg.HOME}/.ssh/nixid_ed25519.pub";
    };
    nixidpubfile_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    nixidssh_pubkey = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
    };
  };


  config.mod_sshkeys = {
    userpkfile_present = builtins.pathExists sshcfg.USERPKFILE;

    userpubfile_present = builtins.pathExists sshcfg.USERPUBFILE;

    nixidpkfile_present = builtins.pathExists sshcfg.NIXIDPKFILE;

    nixidpubfile_present = builtins.pathExists sshcfg.NIXIDPUBFILE;


    userssh_pubkey = lib.mkMerge [ (lib.mkIf sshcfg.userpubfile_present (builtins.concatStringsSep " "
        (lib.lists.take 2 (builtins.filter (e: !(builtins.isList e))
          (builtins.split "[[:space:]\n]+" (builtins.readFile sshcfg.USERPUBFILE))))))
      (lib.mkIf (!sshcfg.userpubfile_present) "")];
    nixidssh_pubkey = lib.mkMerge [ (lib.mkIf sshcfg.nixidpubfile_present (builtins.concatStringsSep " "
        (lib.lists.take 2 (builtins.filter (e: !(builtins.isList e))
          (builtins.split "[[:space:]\n]+" (builtins.readFile sshcfg.NIXIDPUBFILE))))))
      (lib.mkIf (!sshcfg.nixidpubfile_present) "")];
  };
}
