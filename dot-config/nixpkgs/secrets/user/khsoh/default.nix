{
  osConfig,
  config,
  pkgs,
  lib,
  ...
}:
let
  agepkfile = config.agecfg.PKFILE;
  agepubfile = config.agecfg.PUBFILE;
  sshpubfile = config.sshcfg.PUBFILE;
  Helpers = osConfig.helpers;
in
{
  agecfg = {
    OPURI = "op://Private/Personal age private key/notesPlain";
    PKFILE = "~/.age/key.txt";
    PUBFILE = "~/.age/public.txt";
  };

  sshcfg = {
    OPURI = "op://Private/OPENSSH ED25519 Key";
    PKFILE = null;
    PUBFILE = "~/.ssh/id_ed25519.pub";
    pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBUfgkqOXhnONi4FAsFfZFeqW0Bkij6c/6zJf8Il1oCX";
  };

  deployment = lib.mkDefault [
    {
      OPURI = config.agecfg.OPURI;
      FILE = agepkfile;
      POSTCMD = lib.mkDefault [
        "rm -f ${agepubfile}"
        "age-keygen -y -o ${agepubfile} ${agepkfile}"
        "chmod 644 ${agepubfile}"
        "echo \"Generated ${agepubfile} from ${agepkfile}\""
      ];
    }
    {
      OPURI = "${config.sshcfg.OPURI}/public key";
      FILE = sshpubfile;
      POSTCMD = [
        "chmod 644 ${sshpubfile}"
      ];
    }
  ];

  hardlinks = {
    mouseless = lib.mkIf (Helpers.brewAppInstalled "mouseless") {
      source = toString ./homeFile/mouseless.config.yaml;
      target = "Library/Containers/net.sonuscape.mouseless/Data/.mouseless/configs/config.yaml";
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
# vim: set ts=2 sw=2 et ft=nix:
