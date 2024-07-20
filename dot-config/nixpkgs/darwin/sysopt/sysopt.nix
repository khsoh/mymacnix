{ lib, ... }:
{
  options.sysopt = {
    USER = lib.mkOption {
      type = lib.types.str;
      description = "username of the current user account";
      default = builtins.getEnv "USER";
    };
    HOME = lib.mkOption {
      type = lib.types.str;
      description = "The current user's home directory";
      default = builtins.getEnv "HOME";
    };
  };

}
