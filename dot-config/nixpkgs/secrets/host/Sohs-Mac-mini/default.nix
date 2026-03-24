{
  config,
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
    pubkey = (import ./key.nix).pubkey;
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
