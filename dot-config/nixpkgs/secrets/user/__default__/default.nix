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
    OPURI = "op://Nix Bootstrap/NIXID age private key/notesPlain";
    PKFILE = "~/.age/nixid_key.txt";
    PUBFILE = "~/.age/nixid_public.txt";
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
      OPURI = "op://Nix Bootstrap/NIXID SSH Key/private key?ssh-format=openssh";
      FILE = "~/.ssh/nixid_ed25519";
      POSTCMD = [
        "ssh-keygen -y -f ~/.ssh/nixid_ed25519 > ~/.ssh/nixid_ed25519.pub"
        "chmod 644 ~/.ssh/nixid_ed25519.pub"
        "echo \"Generated ~/.ssh/nixid_ed25519.pub from ~/.ssh/nixid_ed25519\""
      ];
    }
  ];
}
