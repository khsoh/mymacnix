{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  isVM = osConfig.machineInfo.is_vm;
  defaultTermPackages =
    (lib.optionals (!isVM) [
      pkgs.kitty
    ])
    ++ [
      pkgs.ghostty-bin
    ];
  userTermFile = "${config.xdg.configHome}/nix/_terminal.nix";
  userTermPath = /. + "${userTermFile}";
  userTermPackages =
    if builtins.pathExists userTermPath then
      import userTermPath { inherit pkgs; }
    else
      defaultTermPackages;

  packageNames = map (pkg: "pkgs.${pkg.pname or "unknown"}") defaultTermPackages;
  formattedString = ''
    { pkgs, ... }:
    [
      ### The default terminal packages here
      ${lib.concatMapStringsSep "\n  " (name: name) packageNames}
    ]
  '';
  activationText = ''
    if [ ! -f "${userTermFile}" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "${userTermFile}")"
      $DRY_RUN_CMD cat <<EOF > "${userTermFile}"
    ${formattedString}
    EOF
    fi
  '';
in
{
  ## Terminal program for user
  options.terminal = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      example = lib.literalExpression "[ pkgs.ghostty-bin pkgs.kitty ]";
      description = ''
        A list of terminal packages to install.  The first package in
        the list is the default terminal to execute at startup.
        Users can override the list with ~/.config/nix/_terminal.nix:

        { pkgs, ... }: [ pkgs.kitty pkgs.ghostty-bin ];
      '';
    };
  };

  config.terminal = {
    packages = userTermPackages;
  };

  config.home.activation.createTerminalTemplate = lib.hm.dag.entryAfter [
    "writeBoundary"
  ] activationText;

  ## Setup checks and asserts for the SSH private and public key files based on
  ## user configuration
  config.assertions = [
    {
      assertion = (!isVM) || (!builtins.elem pkgs.kitty config.terminal.packages);
      message = ''
        kitty terminal program cannot be installed in a VM because VM does not support OpenGL drivers.
        Current terminal packages:

        ${lib.concatMapStringsSep "\n" (name: name) (
          map (pkg: "pkgs.${pkg.pname or "unknown"}") config.terminal.packages
        )}
      '';
    }
  ];
}
# vim: set ts=2 sw=2 et ft=nix:
