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
in
{
  usermap = {
    khsoh = "khsoh";
  };

  agecfg = {
    OPURI = "op://Sohs-Mac-Mini-Secrets/Host age secret key/notesPlain";
    PKFILE = "/etc/age/key.txt";
    PUBFILE = "/etc/age/public.txt";
  };

  onepassword = {
    enable = true;
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

  hostbrew.brews = [
  ];

  hostbrew.casks = [
  ];

  ## Host-specific info for networking
  networking = {
    hostName = "Sohs-Mac-mini";
    localHostName = "Sohs-Mac-mini";
    computerName = "Soh's Mac mini";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
