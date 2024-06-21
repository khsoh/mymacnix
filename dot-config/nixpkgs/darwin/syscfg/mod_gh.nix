{ lib, ... }:
{
  options.mod_gh = {
    enable = lib.mkEnableOption "Enables github module";
    noreply_email = lib.mkOption {
      type = lib.types.str;
      description = "No reply email of your github account";
      default = "none";
    };
  };

}
