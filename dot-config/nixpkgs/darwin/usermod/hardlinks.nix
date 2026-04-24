{
  config,
  lib,
  ...
}:
{
  options.hardlinks = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.path;
            description = "Path of the source file or directory";
          };
          target = lib.mkOption {
            type = lib.types.str;
            description = "Path to the target file relative to HOME";
          };
          postHardlinkCmds = lib.mkOption {
            type = lib.types.str;
            description = "Commands to run after hardlink is created";
            default = "";
          };
        };
      }
    );
    default = { };
    description = "Attribute set of files to hardlink into the home directory.";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
