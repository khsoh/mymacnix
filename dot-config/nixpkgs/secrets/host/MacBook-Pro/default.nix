{
  osConfig,
  config,
  pkgs,
  lib,
  ...
}:
let
  agepkfile = config.agecfg.PKFILE;
  agepubfile = config.agecfg.PUBFILE;
in
{
  usermap = {
    kokhong = "khsoh";
  };

  onepassword = {
    enable = true;
  };

  install_wsgx = true;

  agecfg = {
    OPURI = "op://MacBook-Pro-Secrets/Host age secret key/notesPlain";
    PKFILE = "/etc/age/key.txt";
    PUBFILE = "/etc/age/public.txt";
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

  hostPackages = with pkgs; [
    brave
  ];

  hostbrew.brews = [
  ];

  hostbrew.casks = [
    {
      name = "proton-drive";
      greedy = true;
    }
    {
      name = "displaylink";
      greedy = true;
    }
    {
      name = "loopback";
      greedy = true;
    }
    {
      name = "audio-hijack";
      greedy = true;
    }
    {
      name = "obs";
      greedy = true;
    }
    {
      name = "youlean-loudness-meter";
      greedy = true;
    }
    {
      name = "bazecor";
      greedy = true;
    }
  ];

  hostbrew.masApps = {
    "MoneyWiz" = 1511185140;
    "Telegram" = 747648890;
  };
}
# vim: set ts=2 sw=2 et ft=nix:
