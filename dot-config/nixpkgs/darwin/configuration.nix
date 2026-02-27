{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Declare primary user and home
  primaryUserInfo = import ./_user.nix;

  # The following is example of fixing specific packages to an earlier nixpkgs revision
  # E.g. we can replace pkgs.audacity with pkgs-pinned.audacity
  # pkgs-pinned = import (builtins.fetchTarball {
  #   url = "https://github.com/NixOS/nixpkgs/archive/ed142ab.tar.gz";
  # }) { };

  ## List of users to apply home-manager configuration on
  # Specified as a list of attribute sets that is same
  # as users.users.<name> element
  hmUsers = [
    primaryUserInfo
  ];

  isVM = config.machineInfo.is_vm;

  # 1. Get all user configurations from Home Manager
  allHomeConfigs = builtins.attrValues config.home-manager.users;

  # 2. Extract the 'termpkg' from each user, filtering out nulls
  # We use '?' to safely check if the option exists in their home.nix
  allTerminalPackages = lib.unique (
    lib.flatten (map (cfg: lib.attrByPath [ "terminal" "packages" ] [ ] cfg) allHomeConfigs)
  );

  # 3. Get the onepassword.enable setting of all user packages
  install_onepassword = builtins.any (cfg: cfg.onepassword.enable) allHomeConfigs;

  # Shortcut to get helper functions
  Helpers = config.helpers;
in
{
  imports = [
    ./globals.nix
    <home-manager/nix-darwin>
    <agenix/modules/age.nix>
    ./brews.nix
    ./machine.nix
  ];

  ######### Configuration of modules #########

  ##### home-manager configuration

  ## We use home-manager because this nix-darwin does not seem
  #  to handle the installation of nerdfonts correctly
  #  Note that a function (not attribute) is to be bound to home-manager.users.<name>
  #  Also, it seems that this is a better way to perform user-specific configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  ## Apply home-manager configuration for all users
  home-manager.users = lib.attrsets.genAttrs (map (o: o.name) hmUsers) (_: import ./home.nix);

  ##### end home-manager configuration

  ######### End configuration of modules #########

  ## The following is needed by home-manager to set the
  ##  home.username and home.homeDirectory attributes
  users.users = builtins.listToAttrs (
    map (o: {
      inherit (o) name;
      value = o;
    }) hmUsers
  );

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

  # Setup user specific logfile rotation for all users
  environment.etc = builtins.listToAttrs (
    map (o: {
      name = "newsyslog.d/${o.name}.conf";
      value = {
        text = ''
          ${o.home}/log/*.log      644  5  1024  *  NJ
        '';
      };
    }) hmUsers
  );

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    with pkgs;
    [
      vim
      neovim
      nixd # LSP for nix
      python3
      (callPackage <agenix/pkgs/agenix.nix> { })

      ### The following are for kickstart.nvim
      ripgrep
      unzip
      wget
      fd
      nixfmt

      openssh # Install this as macOS disables use of HW security keys for SSH

      ### The following are to setup use of Yubikey
      yubikey-manager
      yubico-piv-tool

      protonmail-desktop
      bitwarden-desktop
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
      nodejs_22

      vlc-bin
      audacity
      #pkgs-pinned.audacity
      ttyplot
      fastfetch
      zig
      btop

      # The following packages that could not be installed because these are marked as broken
      # handbrake

    ]
    ++ allTerminalPackages
    ++ lib.optionals (install_onepassword) [
      _1password-cli
      _1password-gui
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "${primaryUserInfo.home}/.config/nixpkgs/darwin/configuration.nix";

  # Launch daemon to make root channels public
  launchd.daemons.makeRootChannelsPublic = {
    # The 'script' attribute is not available here. We define the program logic
    # directly in the serviceConfig using ProgramArguments.
    serviceConfig = {
      # The Label is required for launchd
      Label = "org.nixos.makeRootChannelsPublic";

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
    };
  };

  launchd.daemons.generateMachineInfo = {

    serviceConfig = {
      # The Label is required for launchd
      Label = "org.nixos.darwin.generateMachineInfo";
      # Set 'exec' to the absolute path of the generated script in the Nix store
      ProgramArguments = [
        "/etc/nix-darwin/generate_machine_info.sh"
        "/etc/nix-darwin/machine-info.nix"
      ];

      # Monitor this file for modifications
      WatchPaths = [
        "/Library/Preferences/SystemConfiguration/preferences.plist"
      ];

      # Other launchd options
      RunAtLoad = true;
      StartInterval = 3600;
      StandardOutPath = "/var/log/generate-machine-info.log";
      StandardErrorPath = "/var/log/generate-machine-info-error.log";
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
    ${pkgs.fastfetch}/bin/fastfetch
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

  system.primaryUser = primaryUserInfo.name;

  system.defaults.dock = {
    showLaunchpadGestureEnabled = true;
    showMissionControlGestureEnabled = true;
    persistent-apps = lib.filter (a: a != "") (
      [
        "/System/Applications/Apps.app"
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
  #   '';

  system.activationScripts.postActivation.text = lib.mkAfter ''
    PRINT_HEADER=1

    # 1. Map previous binaries to their store paths
    # We use 'find' to safely resolve every symlink in the old bin directory.
    # Result format: "package-name:/nix/store/hash-package-name"
    PREV_MAP=""
    if [ -d "/run/current-system/Applications/" ]; then
      while IFS= read -r app_path; do
        target=$(readlink -f "$app_path")

        # Extract the package name (the part after the hash)
        pkg_name=$(basename "$target")

        # Modify target to get only the one in /nix/store
        target=''${target%/Applications/*}
        # Store as "name:path" for easy lookup
        PREV_MAP="$PREV_MAP$pkg_name:$target"$'\n'
      done < <(find /run/current-system/Applications/ -maxdepth 1 -type l)
    fi

    LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

    # --- Check each package in the new configuration
    ${lib.concatMapStringsSep "\n" (
      pkg:
      let
        pkgName = pkg.pname or (builtins.parseDrvName pkg.name).name;
        appName = Helpers.getMacAppName pkg;
        newPath = "${pkg}";
      in
      ''
        NEW_PATH="${newPath}"
        APP_NAME="${appName}"
        PKG_NAME="${pkgName}"

        # Find the old path by looking for the package name in our map
        OLD_PATH=$(echo "$PREV_MAP" | grep "^$APP_NAME:" | cut -d: -f2- | head -n 1)

        if [[ $PRINT_HEADER -eq 1 && "$OLD_PATH" != "$NEW_PATH" ]]; then
          printf "\n\033[1;34m--- Modified or New Mac Applications ---\033[0m\n"
          PRINT_HEADER=0
        fi


        if [ -z "$OLD_PATH" ]; then
          printf "\033[0;31m[New]\033[0m %s\n" "$APP_NAME - $PKG_NAME"
          echo "  └─ $NEW_PATH"
        elif [ "$OLD_PATH" != "$NEW_PATH" ]; then
          printf "\033[0;31m[Modified]\033[0m %s\n" "$APP_NAME - $PKG_NAME"
          echo "  └─ OLD: $OLD_PATH"
          echo "  └─ NEW: $NEW_PATH"
        fi

        if [[ "$OLD_PATH" != "$NEW_PATH" && -d "/Applications/Nix Apps/$APP_NAME" ]]; then
          # Reset permissions for kitty
          if [[ "$APP_NAME" == "kitty.app" ]]; then
            tccutil reset Accessibility "$(mdls -name kMDItemCFBundleIdentifier -raw "/Applications/Nix Apps/$APP_NAME")"
          fi

          # --- Fix macOS Launch Services for Nix Apps ---
          # This forces macOS to recognize the app bundle immediately after rebuild
          echo "Registering $APP_NAME in /Applications/Nix Apps with Launch Services..."
          $LSREGISTER -f "/Applications/Nix Apps/$APP_NAME"
        fi
      ''
    ) (lib.filter (p: Helpers.getMacAppName p != "") config.environment.systemPackages)}
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  ids.gids.nixbld = config.machineInfo.buildGroupID;
}
# vim: set ts=2 sw=2 et ft=nix:
