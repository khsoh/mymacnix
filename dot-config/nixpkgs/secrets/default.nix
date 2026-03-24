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

  xhost = config._module.args.xhost or null;
  xuser = config._module.args.xuser or null;

  mkHostConfig =
    {
      name,
      config,
      lib,
      options,
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
      ];
    };

  mkUserConfig =
    {
      name,
      config,
      lib,
      options,
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

  cfg = config.secrets;
in
{
  options.secrets = {
    hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule mkHostConfig);
    };
    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule mkUserConfig);
    };

    target = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;

      default = {
        # Point to target host
        host =
          let
            hName = if xhost != null then xhost else config.machineInfo.hostname or "__default__";
          in
          cfg.hosts."${hName}" or cfg.hosts.__default__;

        # Point to target user
        user =
          let
            hName = if xhost != null then xhost else config.machineInfo.hostname or "__default__";
            uName = if xuser != null then xuser else config.system.primaryUser or "__default__";
            myhostcfg = cfg.hosts."${hName}" or cfg.hosts.__default__;
            mappedName = myhostcfg.usermap."${uName}" or myhostcfg.usermap.__default__ or uName;
          in
          cfg.users."${mappedName}" or cfg.users.__default__;
      };

    };
  };

  config = {
    secrets.hosts = importConfig ./host;
    secrets.users = importConfig ./user;
  };

}
# vim: set ts=2 sw=2 et ft=nix:
