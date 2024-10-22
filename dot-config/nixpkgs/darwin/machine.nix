{ config, pkgs, lib, ... }:
{
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
  };

  config.machineInfo = {
    is_vm = (builtins.exec [ "/usr/sbin/sysctl" "-n" "kern.hv_vmm_present" ]) > 0;
    hostname = builtins.exec [ "bash" "-c" ''echo \"$(/usr/sbin/scutil --get LocalHostName)\"'' ];
  };
}
