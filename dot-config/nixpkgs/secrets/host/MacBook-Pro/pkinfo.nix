let
  agepkfile = "/etc/age/key.txt";
  agepubfile = "/etc/age/public.txt";
in
{
  users = {
    # This is an attrset where key is the username at this host and the value is the user info to
    # to collect at ../../user/<value>
    kokhong = "khsoh";
  };
  OPURI = "op://MacBook-Pro-Secrets/Host age secret key/notesPlain";
  pubkey = "age1n3tf4hh64s08ea3jsjkjgeskw5j5yykkyepym4ujkry250n2pqlqmazz7g";
  PKFILE = agepkfile;
  PUBFILE = agepubfile;

  ### List of secrets to deploy - each element contains
  # OPURI - 1Password URI secret reference
  # FILE - target file location - should be in absolute path form (i.e. starts with "/")
  # POSTCMD - A list of commands to execute after the file transfer
  DEPLOY = [
    {
      OPURI = "op://MacBook-Pro-Secrets/Host age secret key/notesPlain";
      FILE = agepkfile;
      POSTCMD = [
        "rsync --remove-source-files -p -chown=root:wheel ./root${agepkfile} ${agepkfile}"
        "age-keygen -y -o ${agepubfile} ${agepkfile}"
        "chmod 644 ${agepubfile}"
      ];
    }
  ];
}
