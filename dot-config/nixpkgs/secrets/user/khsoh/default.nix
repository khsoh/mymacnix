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
}
# vim: set ts=2 sw=2 et ft=nix:
