let
  agepkfile = "~/.age/nixid_key.txt";
  agepubfile = "~/.age/nixid_public.txt";
in
{
  OPURI = "op://Nix Bootstrap/NIXID age private key/notesPlain";
  pubkey = "age1rsuacwv646wtd53kj7j5af5xqjxjw7wtuv33vejr2rgfvvxjufasx32zql";
  PKFILE = agepkfile;
  PUBFILE = agepubfile;

  ### List of secrets to deploy - each element contains
  # OPURI - 1Password URI secret reference
  # FILE - target file location - should start with ~ to store at location relative to home
  # POSTCMD - A list of commands to execute after the file transfer
  DEPLOY = [
    {
      OPURI = "op://Nix Bootstrap/NIXID age private key/notesPlain";
      FILE = agepkfile;
      POSTCMD = [
        "rm -f ${agepubfile}"
        "age-keygen -y -o ${agepubfile} ${agepkfile}"
        "chmod 644 ${agepubfile}"
      ];
    }
    {
      OPURI = "op://Nix Bootstrap/NIXID SSH Key/private key?ssh-format=openssh";
      FILE = "~/.ssh/nixid_ed25519";
      POSTCMD = [
        "ssh-keygen -y -f ~/.ssh/nixid_ed25519 > ~/.ssh/nixid_ed25519.pub"
        "chmod 644 ~/.ssh/nixid_ed25519.pub"
      ];
    }
  ];
}
