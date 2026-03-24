{
  config,
  lib,
  ...
}:
let
  agepkfile = config.agecfg.PKFILE;
  agepubfile = config.agecfg.PUBFILE;
  sshpkfile = config.sshcfg.PKFILE;
  sshpubfile = config.sshcfg.PUBFILE;
in
{
  agecfg = {
    OPURI = "op://Nix Bootstrap/NIXID age private key/notesPlain";
    PKFILE = "~/.age/nixid_key.txt";
    PUBFILE = "~/.age/nixid_public.txt";
    pubkey = (import ./key.nix).pubkey;
  };

  sshcfg = {
    OPURI = "op://Nix Bootstrap/NIXID SSH Key";
    PKFILE = "~/.ssh/nixid_ed25519";
    PUBFILE = "~/.ssh/nixid_ed25519.pub";
    pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQt2ge9t4hjB+S06TUFIFjkaAdqRSx6gitM9rjCSBjl";
  };

  deployment = lib.mkDefault [
    {
      OPURI = config.agecfg.OPURI;
      FILE = config.agecfg.PKFILE;
      POSTCMD = lib.mkDefault [
        "rm -f ${agepubfile}"
        "age-keygen -y -o ${agepubfile} ${agepkfile}"
        "chmod 644 ${agepubfile}"
        "echo \"Generated ${agepubfile} from ${agepkfile}\""
      ];
    }
    {
      OPURI = "${config.sshcfg.OPURI}/private key?ssh-format=openssh";
      FILE = sshpkfile;
      POSTCMD = [
        "ssh-keygen -y -f ${sshpkfile} > ${sshpubfile}"
        "chmod 644 ${sshpubfile}"
        "echo \"Generated ${sshpubfile} from ${sshpkfile}\""
      ];
    }
  ];
}
