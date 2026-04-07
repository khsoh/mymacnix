{
  config,
  options,
  pkgs,
  lib,
  ...
}:
let
  userInfo = import ./userinfo.nix;

  # The following is example of fixing specific packages to an earlier nixpkgs revision
  # E.g. we can replace pkgs.audacity with pkgs-pinned.audacity
  # pkgs-pinned = import (fetchTarball {
  #   url = "https://github.com/NixOS/nixpkgs/archive/09061f748ee2.tar.gz";
  # }) { };
  stdPkgsPath = toString pkgs.path;

  ## List of users to apply home-manager configuration on
  # Specified as a list of attribute sets that is same
  # as users.users.<name> element

  isVM = config.machineInfo.is_vm;

  secretsDir = "${userInfo.home}/.config/nixpkgs/secrets";
  pkhostcfg = config.secrets.target.host;
  pkhostDir = "${secretsDir}/host/${pkhostcfg.name}";
  pkhostPUBFILEstring = lib.strings.trim (builtins.readFile pkhostcfg.agecfg.PUBFILE);

  # 1. Get all user configurations from Home Manager
  allHomeConfigs = builtins.attrValues config.home-manager.users;

  # 2. Extract the 'termpkg' from each user, filtering out nulls
  # We use '?' to safely check if the option exists in their home.nix
  allTerminalPackages = lib.unique (
    lib.flatten (map (cfg: lib.attrByPath [ "terminal" "packages" ] [ ] cfg) allHomeConfigs)
  );

  # 3. Get the onepassword.enable setting of all user packages
  install_onepassword = pkhostcfg.onepassword.enable;

  # Shortcut to get helper functions
  Helpers = config.helpers;
in
{
  imports = [
    ./globals.nix
    <home-manager/nix-darwin>
    <agenix/modules/age.nix>
    <darwin-secrets>
    ./brews.nix
    ./machine.nix
    ./postActivation/dnssetup.nix
    ./postActivation/nixAppsRegister.nix
  ];

  ######### Configuration of modules #########

  ##### agenix configuration
  age.identityPaths = lib.mkIf (builtins.pathExists pkhostcfg.agecfg.PKFILE) [
    pkhostcfg.agecfg.PKFILE
  ];

  ##### home-manager configuration

  ## We use home-manager because this nix-darwin does not seem
  #  to handle the installation of nerdfonts correctly
  #  Note that a function (not attribute) is to be bound to home-manager.users.<name>
  #  Also, it seems that this is a better way to perform user-specific configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  ## Apply home-manager configuration for all users
  home-manager.users."${userInfo.name}" = {
    _module.args.user = userInfo;
    imports = [ ./home.nix ];
  };

  ##### end home-manager configuration

  ######### End configuration of modules #########

  ## The following is needed by home-manager to set the
  ##  home.username and home.homeDirectory attributes
  users.users."${userInfo.name}" = {
    home = userInfo.home;
    uid = userInfo.uid;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-mono
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "1password-cli"
      "1password"
      "discord"
      "google-chrome"
    ];
  # nixpkgs.config.permittedInsecurePackages = [
  #   "google-chrome-144.0.7559.97"
  # ];

  # Files to symlink in /etc
  environment.etc = {
    # Setup user specific logfile rotation for all users
    "newsyslog.d/${userInfo.name}.conf".text = ''
      ${userInfo.home}/log/*.log      644  5  1024  *  NJ
    '';

    # Quad9 Profiles
    "mobileconfig/quad9_secured_dns.mobileconfig" = {
      source = ./profiles/Quad9_Secured_DNS_over_HTTPS_ECS_20260119.mobileconfig;
    };
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    with pkgs;
    [
      vim
      neovim
      neovide
      duti
      rsync
      nixd # LSP for nix
      python3
      age
      nix-prefetch-github
      (callPackage <agenix/pkgs/agenix.nix> { })

      ### The following are for kickstart.nvim
      ripgrep
      unzip
      wget
      fd
      nixfmt

      openssh # Install this as macOS disables use of HW security keys for SSH

      squashfsTools
      discord
      google-chrome
      bat
      tmux
      gnused
      moreutils
      git
      git-credential-manager
      git-lfs
      git-repo
      git-filter-repo
      gh
      tree
      jq
      # dhall-json  ## Remove this because the nds alias can be used instead
      rectangle
      ### Sample demo to use overrideAttrs to embed a postPhase in the installation
      # (_1password-gui.overrideAttrs {
      #   postPhases = [ "mypostrun" ];
      #   mypostrun = ''
      #   echo "Hello World!!!!!"
      #   echo "This is a postPhase that is executed after installation"
      #   '';
      # })
      stow
      cargo
      mupdf
      exiftool
      # The following packages are to support neovim-related builds
      go
      nodejs-slim

      vlc-bin
      audacity
      ttyplot
      fastfetch
      zig
      btop

      # The following packages that could not be installed because these are marked as broken
      # handbrake

    ]
    ++ allTerminalPackages
    ++ lib.optionals install_onepassword [
      _1password-cli # Helpful for deploying secrets
      _1password-gui
    ]
    ++ lib.optionals (!isVM) [
      # Included in builds of the real thing
      ### The following are to setup use of Yubikey
      yubikey-manager
      yubico-piv-tool

      protonmail-desktop
      bitwarden-desktop
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin
  environment.darwinConfig = "${userInfo.home}/.config/nixpkgs/darwin";

  # Append a darwin-secrets path
  nix.nixPath = options.nix.nixPath.default ++ [
    "darwin-secrets=${secretsDir}"
  ];

  # Launch daemon to make root channels public
  launchd.daemons.makeRootChannelsPublic = {
    # The 'script' attribute is not available here. We define the program logic
    # directly in the serviceConfig using ProgramArguments.
    serviceConfig = {
      # The Label is required for launchd
      Label = "org.nixos.makeRootChannelsPublic";

      # Monitor this file for modifications
      WatchPaths = [
        "/var/root/.nix-channels"
      ];

      # Optional: Ensure it runs at least every 10 seconds if many changes happen
      # or if a change is somehow missed, though WatchPaths is generally reliable.
      ThrottleInterval = 10;

      # Run once when the daemon loads (at boot)
      RunAtLoad = true;
      # Do not keep the process alive; launchd will restart it when the file changes
      KeepAlive = false;

      StandardOutPath = "/var/log/org.nixos.makeRootChannelsPublic-Out.log";
      StandardErrorPath = "/var/log/org.nixos.makeRootChannelsPublic-Error.log";

      # ProgramArguments defines what command to run.
      # We use a shell command to execute all the steps sequentially.
      ProgramArguments = [
        "${pkgs.bashInteractive}/bin/bash"
        "-c"
        ''
          mkdir -p /etc/nix-channels
          chmod a+rx /etc/nix-channels
          cp /var/root/.nix-channels /etc/nix-channels/system-channels
          chmod a+r /etc/nix-channels/system-channels
        ''
      ];
    };
  };

  launchd.daemons.generateMachineInfo = {
    serviceConfig = {
      # The Label is required for launchd
      Label = "org.nixos.generateMachineInfo";

      # Monitor this file for modifications
      WatchPaths = [
        "/Library/Preferences/SystemConfiguration/preferences.plist"
      ];

      # Other launchd options
      RunAtLoad = true;
      StartInterval = 3600;
      StandardOutPath = "/var/log/org.nixos.generate-machine-info-Out.log";
      StandardErrorPath = "/var/log/org.nixos.generate-machine-info-Error.log";

      # Set 'exec' to the absolute path of the generated script in the Nix store
      ProgramArguments = [
        "/etc/nix-darwin/generate_machine_info.sh"
        "/etc/nix-darwin/machine-info.nix"
      ];
    };
  };

  launchd.daemons.host-age-validator = lib.mkIf (builtins.pathExists pkhostcfg.agecfg.PKFILE) {
    serviceConfig = {
      Label = "org.nixos.host-age-validator";
      RunAtLoad = true;

      # Use the one-shot settings to prevent looping
      KeepAlive = false;
      AbandonProcessGroup = true;

      WatchPaths = [
        "${dirOf pkhostcfg.agecfg.PKFILE}"
      ];
      StandardOutPath = "/var/log/org.nixos.host-age-check-Out.log";
      StandardErrorPath = "/var/log/org.nixos.host-age-check-Error.log";
      ProgramArguments = [
        "${pkgs.bashInteractive}/bin/bash"
        "-c"
        ''
          sleep 2   # Wait a while for file to be completely updated

          # Runs as root - can read 600 files
          DERIVED=$(${pkgs.age}/bin/age-keygen -y ${pkhostcfg.agecfg.PKFILE} 2>/dev/null)

          if [ "$DERIVED" != "${pkhostPUBFILEstring}" ]; then
            # Find the ID of the currently logged-in user
            CURRENT_USER_ID=$(/usr/bin/id -u $(/usr/bin/stat -f%Su /dev/console))

            # Send notification into that user's session
            /bin/launchctl asuser "$CURRENT_USER_ID" /usr/bin/osascript -e 'display notification "Host Age Private key file ${pkhostcfg.agecfg.PKFILE} does not match with its public key file ${pkhostcfg.agecfg.PUBFILE}!" with title "Security Alert"'
          fi

          if [ "${pkhostPUBFILEstring}" != "${pkhostcfg.agecfg.pubkey}" ]; then
            CURRENT_USER_ID=''${USERID:-$(/usr/bin/id -u $(/usr/bin/stat -f%Su /dev/console))}

            # Send notification into that user's session
            /bin/launchctl asuser "$CURRENT_USER_ID" /usr/bin/osascript -e 'display notification "Contents of Host Age Public key file ${pkhostcfg.agecfg.PUBFILE} does not match with its pubkey attribute value in ${pkhostDir}/default.nix!" with title "Security Alert"'
          fi
        ''
      ];
    };
  };

  launchd.user.agents.monitorQuad9 = {
    serviceConfig = {
      Label = "org.nixos.user.monitorQuad9";
      RunAtLoad = true;
      KeepAlive = false;
      ProcessType = "Background";
      StartInterval = 60 * 60 * 2; # Check every 2 hours
      StandardOutPath = "${userInfo.home}/log/org.nixos.user.monitorQuad9-Out.log";
      StandardErrorPath = "${userInfo.home}/log/org.nixos.user.monitorQuad9-Error.log";
      ProgramArguments = [
        "${pkgs.bashInteractive}/bin/bash"
        "-c"
        ''
          REPO="Quad9DNS/documentation"
          PATH_IN_REPO="docs/assets/mobileconfig"
          ABS_CURRENT_FILE="${
            toString config.environment.etc."mobileconfig/quad9_secured_dns.mobileconfig".source
          }"
          CURRENT_FILE="$(basename $ABS_CURRENT_FILE)"

          API_URL="https://api.github.com/repos/$REPO/contents/$PATH_IN_REPO"
          # Fetch file list from GitHub API
          JQ_PATTERN="Quad9_Secured_DNS_over_HTTPS_ECS_[0-9]{8}\\\\.mobileconfig"
          Q9JSON=$(/usr/bin/curl -s $API_URL | ${pkgs.jq}/bin/jq -c "[.[] | select(.name | test(\"$JQ_PATTERN\"))] | sort_by(.name) | last")

          if [ "$Q9JSON" == "null" ]; then
            >&2 echo "========================"
            >&2 date
            >&2 echo "Error: Could not find any mobileconfig files in the repository."
          else
            LATEST_FILE=$(echo "$Q9JSON" | ${pkgs.jq}/bin/jq -r '.name')
            DOWNLOAD_URL=$(echo "$Q9JSON" | ${pkgs.jq}/bin/jq -r '.download_url')
            FILE_SHA=$(echo "$Q9JSON" | jq -r '.sha')

            if [ "$LATEST_FILE" != "$CURRENT_FILE" ]; then
              >&2 echo "========================"
              >&2 date
              >&2 echo "NEW QUAD9 UPDATE AVAILABLE!"
              >&2 echo "--------------------"
              >&2 echo "Current file: $ABS_CURRENT_FILE"
              >&2 echo "Latest file : $LATEST_FILE"
              >&2 echo "Download URL: $DOWNLOAD_URL"
              >&2 echo "SHA         : $FILE_SHA"
              /usr/bin/osascript -e 'beep' -e "display alert \"QUAD9 Update available\" message \"Latest file : $LATEST_FILE\nDownload URL: $DOWNLOAD_URL\n\nClick OK to download the new update\" buttons {\"Cancel\", \"OK\"} default button \"OK\"" \
              -e "if button returned of result is \"OK\" then open location \"$DOWNLOAD_URL\""
            else
              ## Validate the SHA of the current file
              CURRENT_SHA=$(${pkgs.git}/bin/git hash-object "$ABS_CURRENT_FILE")
              if [ "$FILE_SHA" == "$CURRENT_SHA" ]; then
                echo "========================"
                date
                echo "Quad9 profile is up to date ($ABS_CURRENT_FILE)."
              else
                /usr/bin/osascript -e 'beep' -e "display alert \"Current QUAD9 mobileconfig corrupted!!\" message \"Current SHA-1 of Quad9 mobileconfig at $ABS_CURRENT_FILE did not match official SHA-1\nCurrent : $CURRENT_SHA\nOfficial: $FILE_SHA\""
              fi
            fi
          fi
        ''
      ];
    };
  };

  environment.enableAllTerminfo = true;
  nix.optimise.automatic = true;

  # Setup aliases
  environment.interactiveShellInit = ''
    alias nex="nix --extra-experimental-features nix-command"
    alias nds="nix --extra-experimental-features nix-command derivation show"
    alias enix="nix --extra-experimental-features nix-command"
    alias nie="nix-instantiate --eval"
    alias drb="sudo -H darwin-rebuild build"
    alias drs="sudo -H darwin-rebuild switch"
    alias drlg="sudo -H darwin-rebuild --list-generations"
    alias ..="cd .."
    if [[ $- == *i* ]]; then
      L="$HOME/resize-$TERM_PROGRAM.lock"
      if [[ -n "$RESIZE_TERM" ]]; then
        touch $L
        XRSZ_TERM=$RESIZE_TERM
        unset RESIZE_TERM
        LOGF="$HOME/log/''${XRSZ_TERM}Start.log"
        ((
          trap "rm -f $L" EXIT
          $HOME/.config/jxa/waitapp.js "DisplayLink Manager.app"
          date > $LOGF
          sleep 1
          $HOME/.config/jxa/resize_app.js $XRSZ_TERM >>& $LOGF
          :
        ) >/dev/null 2>&1 &)
      fi

      secs=90
      sleep 0.2
      while [[ -f "$L" && $secs -gt 0 ]]; do
        if [[ $secs -lt 85 ]]; then
          # Print countdown only after 5 seconds
          echo -ne "$secs seconds to starting fastfetch"
          sleep 1
          echo -ne "\033[0K\r"
        else
          sleep 1
        fi
        ((secs--))
      done
      ${pkgs.fastfetch}/bin/fastfetch
    fi
  '';

  # Auto upgrade nix package
  nix.package = pkgs.nix;

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  programs.zsh.promptInit = ''
    [[ -f ${./zshprompt} ]] && source ${./zshprompt}
  '';

  # Create /etc/bashrc
  programs.bash.enable = true;
  programs.bash.interactiveShellInit = ''
    [[ -f ${./bashprompt} ]] && source ${./bashprompt}
  '';

  #!!!! Removed by nix-darwin commit 1d9f622
  # # For /etc/hosts - do not publicize contents for security reasons
  # networking.hostFiles = [ "/etc/hosts.private" ];

  # Add sudo_local security services
  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  # configure sudoers to allow %admin to execute the following sudo commands without password
  security.sudo.extraConfig = ''
    %admin  ALL = (ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild, \
                                  /run/current-system/sw/bin/nix-channel --update, \
                                  /run/current-system/sw/bin/nix-channel --update --verbose, \
                                  /run/current-system/sw/bin/nix-collect-garbage ^--delete-older-than [0-9]+d$, \
                                  /run/current-system/sw/bin/nix-store --gc, \
                                  /usr/bin/sqlite3 --readonly /Library/Application\ Support/com.apple.TCC/TCC.db SELECT\ *\ FROM\ access*
  '';

  system.primaryUser = userInfo.name;

  system.defaults.dock = {
    showLaunchpadGestureEnabled = true;
    showMissionControlGestureEnabled = true;
    persistent-apps = lib.filter (a: a != "") (
      [
        "/System/Applications/Apps.app"
        "/System/Applications/Preview.app"
        "/System/Applications/System Settings.app"
      ]
      ++ lib.optionals (!isVM) [
        "/System/Applications/Calendar.app"
        "/System/Applications/Contacts.app"
        "/System/Applications/Messages.app"
        "/System/Applications/Phone.app"
        "/System/Applications/iPhone Mirroring.app"
        "/System/Applications/Photos.app"
        "/System/Applications/Notes.app"
        "/System/Applications/Reminders.app"
      ]
      ++ map (p: Helpers.getMacBundleAppName p) allTerminalPackages
      ++ lib.optional (Helpers.pkgInstalled pkgs.google-chrome) (
        Helpers.getMacBundleAppName pkgs.google-chrome
      )
      ++ lib.optional (Helpers.brewAppInstalled "brave-browser") "/Applications/Brave Browser.app"
    );
  };
  system.defaults.trackpad = {
    TrackpadFourFingerPinchGesture = 2;
    TrackpadRightClick = true;
    TrackpadPinch = true;
    TrackpadRotate = true;
    TrackpadThreeFingerDrag = true;
    TrackpadThreeFingerHorizSwipeGesture = 1;
  };
  ##### Sample code for system.activationScripts.*.text - this is undocumented
  ###     stuff from nix-darwin
  # system.activationScripts.preActivation.text = ''
  #   if ! /opt/homebrew/bin/brew --version > /dev/null 2>&1 ; then
  #     echo "Installing Homebrew"
  #     NONINTERACTIVE=1 ${pkgs.bashInteractive}/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  #   fi
  #   '';
  # system.activationScripts.postActivation.text = lib.mkAfter ''
  #   echo "I am in PostActivation"
  # '';

  system.activationScripts.postActivation.text =
    let
      # Filter for packages whose source nixpkgs path is non-standard
      excludedPkgs = [ "agenix" ];
      isExternal =
        pkg:
        pkg ? pname
        && !(builtins.elem pkg.pname excludedPkgs)
        && !(lib.hasPrefix stdPkgsPath (toString (pkg.meta.position or "")));

      externalPkgs = builtins.filter isExternal config.environment.systemPackages;
      names = builtins.concatStringsSep "\n\${BLUE}\${BOLD}>>\${ESC} " (
        map (p: p.pname or (lib.getName p)) externalPkgs
      );
    in
    lib.mkIf (externalPkgs != [ ]) (
      lib.mkAfter ''
        # shellcheck disable=SC2034
        ESC="\x1b[0m"
        # shellcheck disable=SC2034
        BOLD="\x1b[1m"
        # shellcheck disable=SC2034
        RED="\x1b[31m"
        # shellcheck disable=SC2034
        GREEN="\x1b[32m"
        # shellcheck disable=SC2034
        YELLOW="\x1b[33m"
        # shellcheck disable=SC2034
        BLUE="\x1b[34m"
        # shellcheck disable=SC2059
        printf "''${GREEN}''${BOLD}======== Packages NOT from main nixpkgs ========''${ESC}\n"
        # shellcheck disable=SC2059
        printf "''${BLUE}''${BOLD}>>''${ESC} ${names}\n"
        # shellcheck disable=SC2059
        printf "''${BLUE}''${BOLD}==>''${ESC} Consider if these packages still require pins.\n"
      ''
    );

  services.openssh.hostKeys = [ ]; # Ensure host keys are not generated

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  ids.gids.nixbld = config.machineInfo.buildGroupID;
}
# vim: set ts=2 sw=2 et ft=nix:
