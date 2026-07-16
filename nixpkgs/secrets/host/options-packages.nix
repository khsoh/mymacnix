{ lib, options, ... }:
{
  options.hostPackages = lib.mkOption {
    type = options.environment.systemPackages.type;
    default = [ ];
    example = lib.literalExpression "[ pkgs.firefox pkgs.brave ]";
    description = ''
      Set of host-specific packages to be appended to environment.systemPackages.
      It is same type as environment.systemPackages.
    '';
  };

  options.masPackages = lib.mkOption {
    type = options.programs.mas.packages.type;
    default = { };
    example = options.programs.mas.packages.example;
    description = options.programs.mas.packages.description;
  };

  config.masPackages = {
    "Xcode" = 497799835;
    "1Password for Safari" = 1569813296;
    "Cursor Pro" = 1447043133;
    "Bible Study" = 472790630;
    "Amazon Kindle" = 302584613;
    "Drafts" = 1435957248;
    "CleanMyMac" = 1339170533;
    "MoneyWiz" = 1511185140;

    ## Apple Apps
    "Keynote" = 409183694;
    "Numbers" = 409203825;
    "Pages" = 409201541;
    "iMovie" = 408981434;
  };
}
# vim: set ts=2 sw=2 et ft=nix:
