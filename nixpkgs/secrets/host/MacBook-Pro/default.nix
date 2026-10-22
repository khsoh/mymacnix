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
  restartApp = config.hostbrew.helpers.restartApp;
  restartApp2 = config.hostbrew.helpers.restartApp2;
in
builtins.seq [ osConfig pkgs restartApp restartApp2 ] {
  usermap = {
    kokhong = "khsoh";
  };

  onepassword = {
    enable = true;
  };

  agecfg = {
    OPURI = "op://MacBook-Pro-Secrets/Host age secret key/notesPlain";
    PKFILE = "/etc/age/key.txt";
    PUBFILE = "/etc/age/public.txt";
  };

  deployment = lib.mkDefault [
    {
      OPURI = config.agecfg.OPURI;
      FILE = config.agecfg.PKFILE;
      POSTCMD = lib.mkDefault [
        "rsync --remove-source-files -p -av --chown=root:wheel ./root${agepkfile} ${agepkfile}"
        "rm -f ${agepubfile}"
        "age-keygen -y -o ${agepubfile} ${agepkfile}"
        "chmod 644 ${agepubfile}"
        "echo \"Generated ${agepubfile} from ${agepkfile}\""
      ];
    }
  ];
}
# vim: set ts=2 sw=2 et ft=nix:
