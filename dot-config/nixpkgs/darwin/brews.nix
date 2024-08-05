{ config, pkgs, lib, ... }:
let
  HOMEDIR = builtins.getEnv "HOME";
  CaskMasDir = "${HOMEDIR}/.config/CaskMasApps/";
  casksnix = CaskMasDir + "casks.nix";
  commoncasksnix = CaskMasDir + "common-casks.nix";
  masappsnix = CaskMasDir + "masapps.nix";
  commonmasappsnix = CaskMasDir + "common-masapps.nix";

  defaultcasksnix = ./default-casks.nix;
  defaultmasappsnix = ./default-masapps.nix;

  CASKROOM = /opt/homebrew/Caskroom;
  ## List of user casks that follows the nix-darwin format for
  ##  each element of homebrew.casks attribute set entry
  ## The "appname" field is removed by the BrewCask function
  ##  to make the USERCASKS compatible with the homebrew.casks
  ##  entry
  ##
  ## The appname entry is used to filter out applications that
  ##  were already installed before Homebrew.  This specifies
  ##  the application name under the /Applications folder.
  AppExists = (appName: builtins.pathExists (/Applications + "/${appName}"));
  CaskInstalled = (n: builtins.pathExists (CASKROOM + "/${n}"));

  ## Casks are machine dependent
  USERCASKS = if builtins.pathExists casksnix then
    import casksnix ++ import commoncasksnix
    else import defaultcasksnix;
  MASAPPS = if builtins.pathExists masappsnix then
    lib.trivial.mergeAttrs (import masappsnix) (import commonmasappsnix)
    else import defaultmasappsnix;

  caskOptions = [ "name" "args" "greedy" ];
  BrewCask = (casks:
    builtins.map (e: lib.attrsets.filterAttrs (n: v: builtins.elem n caskOptions) e)
    (builtins.filter (e: (!AppExists e.appname) || (CaskInstalled e.name)) casks));
in {
  ### Homebrew setup.  Default it to false
  homebrew.enable = true;

  homebrew.brews = [
    "mas"
  ];

  homebrew.casks = BrewCask USERCASKS;

  homebrew.masApps = MASAPPS;

  ## The following allows Nix to uninstall stuff absent from cask list
  homebrew.onActivation.cleanup = "zap";
}

