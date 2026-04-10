{
  config,
  pkgs,
  lib,
  options,
  ...
}:
let
  # Helper: List all directories in a path
  getDirs =
    path:
    builtins.attrNames (lib.filterAttrs (name: type: type == "directory") (builtins.readDir path));

  mkHostConfig =
    {
      name,
      lib,
      ...
    }:
    {
      options.name = lib.mkOption {
        type = lib.types.str;
        description = "The <hostname> folder in the <darwin-secrets>/host/<hostname>";
        default = name;
      };

      imports = [
        ./common/options-deploy.nix
        ./common/options-wsgx.nix
        ./common/options-age.nix
        ./common/options-ssh.nix
        ./host/options-usermap.nix
        ./host/options-1password.nix
        ./host/options-packages.nix
        ./host/options-hostbrew.nix
      ];
    };

  mkUserConfig =
    {
      name,
      lib,
      ...
    }:
    {
      options.name = lib.mkOption {
        type = lib.types.str;
        description = "The <username> folder in the <darwin-secrets>/user/<username>";
        default = name;
      };

      imports = [
        ./common/options-deploy.nix
        ./common/options-age.nix
        ./common/options-ssh.nix
      ];
    };

  importConfig =
    base:
    let
      subdirs = getDirs base;
    in
    lib.genAttrs subdirs (name: import (base + "/${name}"));

  ## Function to extract first 2 elements of the public key file
  mkAbsPath =
    filePath:
    let
      absfile =
        if builtins.substring 0 1 filePath == "~" then
          config.users.users.${config.system.primaryUser}.home
          + builtins.substring 1 (builtins.stringLength filePath) filePath
        else
          filePath;
    in
    absfile;

  readPubkey =
    pubkeyfile:
    let
      absfile = mkAbsPath pubkeyfile;
      # Read the file and strip the trailing newline
      content = lib.removeSuffix "\n" (builtins.readFile absfile);
      # Split by spaces into a list of strings
      parts = lib.splitString " " content;
    in
    # Take the first two elements and join them with a space
    builtins.concatStringsSep " " (lib.take 2 parts);

  cfg = config.secrets;
  cfguser = cfg.target.user;
  sshpkfile = cfguser.sshcfg.PKFILE;
  sshpubfile = cfguser.sshcfg.PUBFILE;
  sshpubkey = cfguser.sshcfg.pubkey;
in
{
  options.secrets = {
    hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          modules = [ mkHostConfig ];
          specialArgs = {
            inherit pkgs options;
            osConfig = config;
          };
        }
      );
    };
    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          modules = [ mkUserConfig ];
          specialArgs = {
            inherit pkgs;
            osConfig = config;
          };
        }
      );
    };

    target = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;

      default = {
        # Point to target host
        host = cfg.hosts."${config.machineInfo.hostname}" or cfg.hosts.__default__;

        # Point to target user
        user =
          let
            hName = config.machineInfo.hostname or "__default__";
            uName = config.system.primaryUser or "__default__";
            myhostcfg = cfg.hosts."${hName}" or cfg.hosts.__default__;
            mappedName = myhostcfg.usermap."${uName}" or uName;
          in
          cfg.users."${mappedName}" or cfg.users.__default__;
      };

    };
  };

  config = {
    secrets.hosts = importConfig ./host;
    secrets.users = importConfig ./user;

    assertions = [
      {
        # Check the target user private key file
        assertion = (sshpkfile == null) || (builtins.pathExists (mkAbsPath sshpkfile));
        message = "Check the sshcfg.PKFILE definition in ${<darwin-secrets>}/user/${cfguser.name}/default.nix.  The ${sshpkfile} SSH private key file is absent - file must be present to build";
      }

      {
        # Check that the target user public key file contents and pubkey match
        assertion =
          (sshpubfile == null)
          || (!builtins.pathExists (mkAbsPath sshpubfile))
          || ((readPubkey sshpubfile) == sshpubkey);
        message = "Check the sshcfg.PUBFILE and sshcfg.pubkey definition in ${<darwin-secrets>}/user/${cfguser.name}/default.nix.  Contents of ${sshpubfile} do not match the sshcfg.pubkey string";
      }
    ];
  };

}
# vim: set ts=2 sw=2 et ft=nix:
