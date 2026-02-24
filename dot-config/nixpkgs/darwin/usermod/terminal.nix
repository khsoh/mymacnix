{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  isVM = osConfig.machineInfo.is_vm;
  usertermfile = /. + "${config.xdg.configHome}/nix/_terminal.nix";
  usertermcfg =
    if builtins.pathExists usertermfile then
      import usertermfile { inherit pkgs; }
    else
      { package = (if (!isVM) then pkgs.kitty else pkgs.ghostty-bin); };
in
{
  ## Terminal program for user
  options.terminal = {
    package = lib.mkPackageOption pkgs [ "ghostty-bin" "kitty" ] {
      nullable = true;
      default = null;
      extraDescription = "Terminal package to install";
    };
  };

  config.terminal = {
    package = usertermcfg.package;
  };

  ## Setup checks and asserts for the SSH private and public key files based on
  ## user configuration
  config.assertions = [
    {
      assertion = (!isVM) || (config.terminal.package != pkgs.kitty);
      message = "kitty terminal program cannot be installed in a VM because VM does not support OpenGL drivers";
    }
  ];
}
# vim: set ts=2 sw=2 et ft=nix:
