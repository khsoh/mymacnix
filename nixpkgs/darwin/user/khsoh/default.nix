{
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  Helpers = osConfig.helpers;
in
builtins.seq [ pkgs lib ] {
  hardlinks = {
    mouseless = lib.mkIf (Helpers.brewAppInstalled "mouseless") {
      source = toString ./homeFile/mouseless.config.yaml;
      target = "Library/Application Support/Mouseless/configs/config.yaml";
    };

    rectangle = lib.mkIf (Helpers.pkgInstalled pkgs.rectangle) {
      source = toString ./homeFile/com.knollsoft.Rectangle.plist;
      target = "Library/Preferences/com.knollsoft.Rectangle.plist";
      postHardlinkCmds =
        let
          defaults = "/usr/bin/defaults";
          killall = "/usr/bin/killall";
        in
        ''
          run ${defaults} read com.knollsoft.Rectangle > /dev/null
          run ${killall} cfprefsd || true
        '';
    };
  };
}
