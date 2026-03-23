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
  };

  config.secrets.hosts = importConfig ./host;
  config.secrets.users = importConfig ./user;

  config.lib.secrets = {
    getMyHostConfig = cfg.hosts."${config.machineInfo.hostname}" or cfg.hosts.__default__;

    getMyUserConfig =
      let
        uName = config.system.primaryUser;
        myhostcfg = config.lib.secrets.getMyHostConfig;
        mappedName = myhostcfg.usermap."${uName}" or myhostcfg.usermap.__default__;
      in
      cfg.users."${mappedName}";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
