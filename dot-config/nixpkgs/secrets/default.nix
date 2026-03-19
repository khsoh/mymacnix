{
  host ? null,
  user ? null,
  pkgs ? null,
  lib ? null,
  config ? null,
  osConfig ? null,
  ...
}@args:
let
  # 1. Detect environment
  isSystem = (config != null) || (osConfig != null);

  # 2. Assign Library and Package set
  # Use provided system args, otherwise fall back to standalone import
  finalPkgs = if pkgs != null then pkgs else import <nixpkgs> { };
  finalLib = if lib != null then lib else finalPkgs.lib;

  _check =
    if !isSystem then
      assert
        (host == null) == (user == null)
        || throw "Error: Both 'host' and 'user' must be provided or NEITHER provided (force detect local user and host)";
      true
    else
      true;

  # 3. DETECT CONTEXT
  # Nix-Darwin passes 'config.system'
  isDarwin = args ? config.system;
  # Home Manager passes 'config.home'
  isHomeManager = args ? config.home;
  isStandalone = !isDarwin && !isHomeManager;

  userinfo = import <darwin-config/userinfo.nix>;
  currentUser = userinfo.name;
  currentHost = (import "/etc/nix-darwin/machine-info.nix").hostname;

  # PATH RESOLUTION (No /nix/store copies)
  # Uses '+' to keep paths on local disk
  resolveName =
    base: sub:
    let
      p = base + "/${sub}";
    in
    if builtins.pathExists p then sub else "__default__";

  resolvePath = base: sub: (base + "/${resolveName base sub}");

  # Helper: List all directories in a path
  getDirs =
    path:
    builtins.attrNames (finalLib.filterAttrs (name: type: type == "directory") (builtins.readDir path));

  mkHostEval =
    { hName }:
    finalLib.evalModules {
      modules = [
        ./common/options-age.nix
        ./common/options-deploy.nix
        ./common/options-wsgx.nix
        ./host/options-usermap.nix
        (resolvePath ./host hName)
      ];
      specialArgs = {
        pkgs = finalPkgs;
        lib = finalLib;
        xhost = resolveName ./host hName;
      };
    };

  mkUserEval =
    { uName }:
    finalLib.evalModules {
      modules = [
        ./common/options-age.nix
        ./common/options-deploy.nix
        (resolvePath ./user uName)
      ];
      specialArgs = {
        pkgs = finalPkgs;
        lib = finalLib;
        xuser = resolveName ./user uName;
      };
    };

  effectiveHost = if host != null then host else currentHost;
  ## These are the key data for current host and current user
  pkhost = (mkHostEval { hName = effectiveHost; }).config;

  # Translate the user based on the host usermap
  xUser = if user != null then user else currentUser;
  effectiveUser = pkhost.usermap."${xUser}" or "__default__";
  pkuser =
    if (isHomeManager || isStandalone) then (mkUserEval { uName = effectiveUser; }).config else { };
in
{
  _dummy = _check;
  users = finalLib.mkIf isStandalone (
    finalLib.genAttrs (getDirs ./user) (u: (mkUserEval { uName = u; }).config)
  );
  hosts = finalLib.mkIf isStandalone (
    finalLib.genAttrs (getDirs ./host) (h: (mkHostEval { hName = h; }).config)
  );

  inherit pkhost pkuser;
}
# vim: set ts=2 sw=2 et ft=nix:
