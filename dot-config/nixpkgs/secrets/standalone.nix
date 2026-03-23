{
  host,
  user,
}:
let
  # Mocking the library and pkgs for the standalone call
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # Evaluate the module manually
  eval = lib.evalModules {
    modules = [
      <darwin-secrets>
      {
        # Provide dummy values for the module arguments
        _module.args = {
          inherit pkgs lib;
          xhost = host;
          xuser = user;
        };
      }
    ];
  };
in
eval.config.secrets
