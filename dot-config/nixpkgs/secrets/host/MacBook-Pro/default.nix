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
  restartApp = config.hostbrew.helpers.restartApp;
  restartApp2 = config.hostbrew.helpers.restartApp2;
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

  hostbrew.brews = [
  ];

  hostbrew.casks = [
    {
      name = "mouseless";
      greedy = true;
      postinstall = restartApp2 "Mouseless" "mouseless";
    }
    {
      name = "discord";
      greedy = true;
      postinstall = restartApp "Discord";
    }
    {
      name = "dropbox";
      greedy = true;
      postinstall = restartApp "Dropbox";
    }
    {
      name = "displaylink";
      greedy = true;
      postinstall = restartApp "DisplayLink Manager";
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
    {
      name = "ibkr";
      greedy = true;
    }
  ];

  hostbrew.masApps = {
    "Telegram" = 747648890;
  };
}
# vim: set ts=2 sw=2 et ft=nix:
