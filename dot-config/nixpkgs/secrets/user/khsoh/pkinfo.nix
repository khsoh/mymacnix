let
  agepkfile = "~/.age/key.txt";
  agepubfile = "~/.age/public.txt";
in
{
  OPURI = "op://Private/Personal age private key/notesPlain";
  pubkey = "age1wl5azg6umw6uevcwwxvmjszf3unrh6huj8xcwaupxyatrr75dfuq6x636s";
  PKFILE = agepkfile;
  PUBFILE = agepubfile;

  ### List of secrets to deploy - each element contains
  # OPURI - 1Password URI secret reference
  # FILE - target file location - should start with ~ to store at location relative to home
  # POSTCMD - A list of commands to execute after the file transfer
  DEPLOY = [
    {
      OPURI = "op://Private/Personal age private key/notesPlain";
      FILE = agepkfile;
      POSTCMD = [
        "chmod 600 ${agepkfile}"
        "age-keygen -y -o ${agepubfile} ${agepkfile}"
        "chmod 644 ${agepubfile}"
      ];
    }
  ];
}
