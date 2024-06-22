{ config, lib, ... }:
let
  syscfg = config.sysopt;
  sshcfg = config.mod_sshkeys;

  file_presence = (errcheck: errmsg: cond: trueresult: falseresult: 
    lib.mkMerge [ (lib.mkIf cond trueresult)
      (lib.mkIf (!cond) ((lib.trivial.throwIf errcheck errmsg) falseresult))
      ]);
  read_pubkey = (filepresent: pubkeyfile: lib.mkMerge [ (lib.mkIf filepresent (builtins.concatStringsSep " "
      (lib.lists.take 2 (builtins.filter (e: !(builtins.isList e))
        (builtins.split "[[:space:]\n]+" (builtins.readFile pubkeyfile))))))
    (lib.mkIf (!filepresent) "")]);
in {

  ## SSH private and public keys for the user and Nix
  # It is possible to build system without a user private keyfile.
  # This is to build for systems running on a VM - so that the
  # chance of leaking the user private key is minimized
  # So, when running in VM, the USERPKFILE need not be present

  ## Important - we must not use lib.types.path - otherwise the file
  # may be copied to /nix/store
  # Paths are relative to HOME folder
  #
  # The options *_present are readOnly flags to indicate whether
  # the specified files are present.
  options.mod_sshkeys = {

    USERPKFILE = lib.mkOption {
      type = lib.types.str;
      description = "Relative path to current user's secret key file";
      default = "${syscfg.HOME}/.ssh/id_ed25519";
    };
    check_userpkfile = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    userpkfile_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };

    USERPUBFILE = lib.mkOption {
      type = lib.types.path;
      description = "Relative path to current user's public key file";
      default = "${syscfg.HOME}/.ssh/id_ed25519.pub";
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
      type = lib.types.str;
      readOnly = true;
    };

    NIXIDPKFILE = lib.mkOption {
      type = lib.types.str;
      description = "Relative path to Nix system's secret key file";
      default = "${syscfg.HOME}/.ssh/nixid_ed25519";
    };
    check_nixidpkfile = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    nixidpkfile_present = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };

    NIXIDPUBFILE = lib.mkOption {
      type = lib.types.path;
      description = "Relative path to Nix system's public key file";
      default = "${syscfg.HOME}/.ssh/nixid_ed25519.pub";
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
      type = lib.types.str;
      readOnly = true;
    };
  };


  config.mod_sshkeys = {
    userpkfile_present = file_presence sshcfg.check_userpkfile ''
      The user ssh private key file ${sshcfg.USERPKFILE} is absent - this file must be present to build
      '' 
      (builtins.pathExists sshcfg.USERPKFILE) true false;

    userpubfile_present = file_presence sshcfg.check_userpubfile ''
      The user ssh public key file ${sshcfg.USERPUBFILE} is absent - this file must be present to build
      '' 
      (builtins.pathExists sshcfg.USERPUBFILE) true false;

    nixidpkfile_present = file_presence sshcfg.check_nixidpkfile ''
      The NIXID ssh private key file ${sshcfg.NIXIDPKFILE} is absent - this file must be present to build
      '' 
      (builtins.pathExists sshcfg.NIXIDPKFILE) true false;

    nixidpubfile_present = file_presence sshcfg.check_nixidpubfile ''
      The NIXID ssh public key file ${sshcfg.NIXIDPUBFILE} is absent - this file must be present to build
      '' 
      (builtins.pathExists sshcfg.NIXIDPUBFILE) true false;


    userssh_pubkey = read_pubkey sshcfg.userpubfile_present sshcfg.USERPUBFILE;
    nixidssh_pubkey = read_pubkey sshcfg.nixidpubfile_present sshcfg.NIXIDPUBFILE;
  };
}