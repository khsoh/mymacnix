{
  osConfig,
  config,
  lib,
  ...
}:
let
  agepkfile = config.agecfg.PKFILE;
  agepubfile = config.agecfg.PUBFILE;
in
{
  agecfg = {
    OPURI = "op://Nix Bootstrap/Default Machine age secret key/notesPlain";
    PKFILE = "/etc/age/nixid_host_key.txt";
    PUBFILE = "/etc/age/nixid_host_public.txt";
  };

  onepassword = {
    enable = !osConfig.machineInfo.is_vm;
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
