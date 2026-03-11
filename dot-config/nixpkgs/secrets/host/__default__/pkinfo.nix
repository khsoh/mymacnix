let
  agepkfile = "/etc/age/nixid_host_key.txt";
  agepubfile = "/etc/age/nixid_host_public.txt";
in
{
  users = {
    # This is an attrset where key is the username at this host and the value is the user info to
    # to collect at ../../user/<value>
    __default__ = "__default__";
  };
  OPURI = "op://Nix Bootstrap/Default Machine age secret key/notesPlain";
  pubkey = "age1lgfx8jh6htcjsf7uw9sqwtynpknpdln04ytj335anedy4hderayqar3h6k";
  PKFILE = agepkfile;
  PUBFILE = agepubfile;

  ### List of secrets to deploy - each element contains
  # OPURI - 1Password URI secret reference
  # FILE - target file location - should be in absolute path form (i.e. starts with "/")
  # POSTCMD - A list of commands to execute after the file transfer
  DEPLOY = [
    {
      OPURI = "op://Nix Bootstrap/Default Machine age secret key/notesPlain";
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
