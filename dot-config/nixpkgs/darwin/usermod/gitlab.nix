{ lib, ... }:
{
  options.gitlab = {
    enable = lib.mkEnableOption "Enables gitlab module";
    noreply_email = lib.mkOption {
      type = lib.types.str;
      description = "No reply email of your gitlab account";
      default = "none";
    };
    username = lib.mkOption {
      type = lib.types.str;
      description = "Username of gitlab account";
    };
  };

  config.gitlab = {
    enable = lib.mkDefault false;
    username = "khsoh";
  };
}
