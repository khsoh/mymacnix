let
  agepkfile = "/etc/age/key.txt";
  agepubfile = "/etc/age/public.txt";
in
{
  users = {
    # This is an attrset where key is the username at this host and the value is the user info to
    # to collect at ../../user/<value>
    khsoh = "khsoh";
  };
  OPURI = "op://Sohs-Mac-Mini-Secrets/Host age secret key/notesPlain";
  pubkey = "age1arj7s4zcud0rtj8vjnt8nrkxpump506x4qts9l4uhnv65uedrcjslmzfej";
  PKFILE = agepkfile;
  PUBFILE = agepubfile;

  ### List of secrets to deploy - each element contains
  # OPURI - 1Password URI secret reference
  # FILE - target file location - should be in absolute path form (i.e. starts with "/")
  DEPLOY = [
    {
      OPURI = "op://Sohs-Mac-Mini-Secrets/Host age secret key/notesPlain";
      FILE = agepkfile;
      POSTCMD = [
        "rsync --remove-source-files -p -av --chown=root:wheel ./root${agepkfile} ${agepkfile}"
        "rm -f ${agepubfile}"
        "age-keygen -y -o ${agepubfile} ${agepkfile}"
        "chmod 644 ${agepubfile}"
        "echo \"Generated ${agepubfile} from ${agepkfile}\""
      ];
    }
  ];
}
