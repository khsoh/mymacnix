{ config, pkgs, lib, ... }:
let
  # Import the generated file.
  # Use a fallback value if the file doesn't exist yet to allow the first build to succeed.
  machineInfo =
    if builtins.pathExists "/etc/nix-darwin/machine-info.nix"
    then import "/etc/nix-darwin/machine-info.nix"
    else { is_vm = 0; hostname = "unknown"; buildGroupID = 350; };

in {
  options.machineInfo = {
    is_vm = lib.mkOption {
      type = lib.types.bool;
      description = ''
        True if this is a virtual machine
        '';
      readOnly = true;
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      description = ''
        Local hostname of machine
        '';
      readOnly = true;
    };

    buildGroupID = lib.mkOption {
      type = lib.types.int;
      description = ''
        Nix build group ID
        '';
      readOnly = true;
    };
  };

  config.machineInfo = {
    is_vm = machineInfo.is_vm > 0;
    hostname = machineInfo.hostname;
    buildGroupID = machineInfo.buildGroupID;
  };
}
