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
  agecfg = {
    OPURI = "op://Private/Personal age private key/notesPlain";
    PKFILE = "~/.age/key.txt";
    PUBFILE = "~/.age/public.txt";
    pubkey = (import ./key.nix).pubkey;
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
      OPURI = "op://Private/OPENSSH ED25519 Key/public key";
      FILE = "~/.ssh/id_ed25519.pub";
      POSTCMD = [
        "chmod 644 ~/.ssh/id_ed25519.pub"
      ];
    }
  ];
}
