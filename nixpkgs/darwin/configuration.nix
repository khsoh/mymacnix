{
  config,
  options,
  pkgs,
  lib,
  ...
}:
let
  userInfo = import ./userinfo.nix;

  ## List of users to apply home-manager configuration on
  # Specified as a list of attribute sets that is same
  # as users.users.<name> element

  isVM = config.machineInfo.is_vm;

  secretsDir = "${userInfo.home}/.config/nixpkgs/secrets";
  pkhostcfg = config.secrets.target.host;
  pkhostDir = "${secretsDir}/host/${pkhostcfg.name}";
  pkhostPUBFILEstring = lib.strings.trim (builtins.readFile pkhostcfg.agecfg.PUBFILE);

  valkey_base_port = 6379;
  valkey_port = valkey_base_port + userInfo.uid;
  valkey_dir = "${userInfo.home}/.local/share/valkey-private-data";

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

  # 1. Isolate the highest priority "nixpkgs" path from NIX_PATH
  allNixpkgsEntries = builtins.filter (x: x.prefix == "nixpkgs") builtins.nixPath;
  highestPriorityEntry =
    if builtins.length allNixpkgsEntries > 0 then builtins.elemAt allNixpkgsEntries 0 else null;
  activeNixpkgsPathStr =
    if highestPriorityEntry != null then toString highestPriorityEntry.path else "";

  # 2. Extract the exact hash from the -I archive URL string
  urlMatch = builtins.match ".*archive/([0-9a-fA-F]{7,40})\\.tar\\.gz" activeNixpkgsPathStr;
  currentRevision = if urlMatch != null then builtins.head urlMatch else null;
in
{
  # Replace with pkgs-pinned packages (the default)
  nixpkgs.overlays = import ./overlays.nix;

  imports = [
    ./globals.nix
    <home-manager/nix-darwin>
    <agenix/modules/age.nix>
    <darwin-secrets>
    ./brews.nix
    ./machine.nix
    ./postActivation
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
    ];

  # Files to symlink in /etc
  environment.etc = {
    # Setup user specific logfile rotation for all users
    "newsyslog.d/${userInfo.name}.conf".text = ''
      # logfilename                                         [owner[:group]]   mode count  size  when  flags
      ${userInfo.home}/log/[!.]*.log                        ${userInfo.name}  644  5      1024  *     NJG
      ${userInfo.home}/.local/state/nvim/[!.]*.log          ${userInfo.name}  644  3      1024  *     NJG
      ${userInfo.home}/.local/state/nvim-minimax/[!.]*.log  ${userInfo.name}  644  3      1024  *     NJG
      ${userInfo.home}/.local/state/nvtest/[!.]*.log        ${userInfo.name}  644  3      1024  *     NJG
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
      ## Viewers, editors and supporting utilities
      vim
      neovim
      neovide
      tree
      mupdf

      ## Programming development
      git
      git-credential-manager
      git-lfs
      git-repo
      git-filter-repo
      gh

      ## LSPs for Neovim
      nixd
      lua-language-server
      bash-language-server
      typescript-language-server
      biome # Is also formatter and linter for JavaScript, TypeScript, JSON
      marksman # Markdown
      powershell-editor-services # PowerShell
      powershell
      pyright # Python
      clang-tools # clangd
      gopls # Go
      rust-analyzer # Rust
      rustc # Rust
      zls # Zig
      lemminx # XML
      superhtml # HTML

      ## Formatters for Neovim
      nixfmt
      stylua
      prettier
      shfmt # Formatter for bash - called by bashls
      ruff # Formatter and linter for python

      ## Linters for Neovim
      shellcheck

      ## Parsing engine for Neovim
      tree-sitter

      python3
      nix-prefetch-github
      cargo
      zig
      # The following packages are to support neovim-related builds
      go
      nodejs

      # Required for peek.nvim execution
      deno

      # Security related packages
      gnupg
      age
      (callPackage <agenix/pkgs/agenix.nix> { })
      openssh # Install this as macOS disables use of HW security keys for SSH

      ## System Utilities
      valkey
      duti
      rsync
      ripgrep
      unzip
      wget
      fd
      squashfsTools
      bat
      gnused
      moreutils
      jq
      exiftool
      ttyplot
      fastfetch
      btop
      hyperfine

      ## Desktop and terminal related packages
      tmux
      rectangle
      stow

      ### Sample demo to use overrideAttrs to embed a postPhase in the installation
      # (_1password-gui.overrideAttrs {
      #   postPhases = [ "mypostrun" ];
      #   mypostrun = ''
      #   echo "Hello World!!!!!"
      #   echo "This is a postPhase that is executed after installation"
      #   '';
      # })

      ## The following packages that could not be installed because these are marked as broken
      # handbrake
    ]
    ++ allTerminalPackages
    ++ lib.optionals install_onepassword [
      _1password-cli # Helpful for deploying secrets
      _1password-gui
    ]
    ++ pkhostcfg.hostPackages
    ++ lib.optionals (!isVM) [
      # Included in builds of the real thing
      ### The following are to setup use of Yubikey
      yubikey-manager
      yubico-piv-tool

      protonmail-desktop
      bitwarden-desktop

      element-desktop

      # For installing mas packages
      mas

      ## VM related stuff
      utm
      podman
      rustup

      ## Multimedia related utilities
      vlc-bin
      audacity

      ## P2P support
      iroh-ssh

      ## Yabai to talk to macOS WindowServer
      yabai
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin
  environment.darwinConfig = "${userInfo.home}/.config/nixpkgs/darwin";

  environment.variables = {
    HOMEBREW_UPDATE_TO_TAG = "1";
    VALKEY_PORT = "$((${toString valkey_base_port}+$UID))";
  };

  # Append a darwin-secrets path
  nix.nixPath = options.nix.nixPath.default ++ [
    "darwin-secrets=${secretsDir}"
  ];

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
        "${pkgs.zsh}/bin/zsh"
        "-c"
        # zsh
        ''
          # Ensure system and core binaries are accessible within the launchd sandbox
          export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"

          NIX_DARWIN_DIR="/etc/nix-darwin"
          MINFO_FILE="$NIX_DARWIN_DIR/machine-info.nix"

          mkdir -p "$NIX_DARWIN_DIR"

          IS_VM=$(/usr/sbin/sysctl -n kern.hv_vmm_present 2>/dev/null || echo "0")
          XHOSTNAME=$(/usr/sbin/scutil --get LocalHostName)

          BGROUPID=$(dscl . -read /Groups/nixbld PrimaryGroupID 2>/dev/null | awk '{ print $2 }')
          if [ -z "$BGROUPID" ]; then
            BGROUPID=350
          fi

          # nix
          NEW_MINFO="{
            is_vm = $IS_VM;
            hostname = \"$XHOSTNAME\";
            buildGroupID = $BGROUPID;
          }"

          if [ ! -f "$MINFO_FILE" ] || ! diff -q "$MINFO_FILE" - <<< "$NEW_MINFO" >/dev/null 2>&1; then
              echo "$NEW_MINFO" > "$MINFO_FILE"
          fi
        ''
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
        "${pkgs.zsh}/bin/zsh"
        "-c"
        # zsh
        ''
          sleep 2   # Wait a while for file to be completely updated

          # Runs as root - can read 600 files
          DERIVED=$(${pkgs.age}/bin/age-keygen -y ${pkhostcfg.agecfg.PKFILE} 2>/dev/null | /usr/bin/tr -d '\n')

          if [[ "$DERIVED" != "${pkhostPUBFILEstring}" ]]; then
            # Find the ID of the currently logged-in user
            CURRENT_USER_ID=$(/usr/bin/id -u $(/usr/bin/stat -f%Su /dev/console))

            # Send notification into that user's session
            /bin/launchctl asuser "$CURRENT_USER_ID" /usr/bin/osascript -l JavaScript <<'EOF_javascript'
              var app = Application.currentApplication();
              app.includeStandardAdditions = true;

              app.displayNotification("Host Age Private key file ${pkhostcfg.agecfg.PKFILE} does not match with its public key file ${pkhostcfg.agecfg.PUBFILE}!", { withTitle: "Security Alert" });
              void(0);
          EOF_javascript
          fi

          if [[ "${pkhostPUBFILEstring}" != "${pkhostcfg.agecfg.pubkey}" ]]; then
            CURRENT_USER_ID=''${USERID:-$(/usr/bin/id -u $(/usr/bin/stat -f%Su /dev/console))}

            # Send notification into that user's session
            /bin/launchctl asuser "$CURRENT_USER_ID" /usr/bin/osascript -l JavaScript <<'EOF_javascript'
              var app = Application.currentApplication();
              app.includeStandardAdditions = true;

              app.displayNotification("Contents of Host Age Public key file ${pkhostcfg.agecfg.PUBFILE} does not match with its pubkey attribute value in ${pkhostDir}/default.nix!", { withTitle: "Security Alert" });
              void(0);
          EOF_javascript
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
        "${pkgs.zsh}/bin/zsh"
        "-c"
        # zsh
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
          Q9JSON=$(/usr/bin/curl --retry 3 -s $API_URL | ${pkgs.jq}/bin/jq -c "[.[] | select(.name | test(\"$JQ_PATTERN\"))] | sort_by(.name) | last" 2>/dev/null)

          if [[ ! -n "$Q9JSON" || "$Q9JSON" == "[]" ]]; then
            >&2 echo "========================"
            >&2 date
            >&2 echo "Error: Could not find any mobileconfig files in the repository."
          else
            LATEST_FILE=$(echo "$Q9JSON" | ${pkgs.jq}/bin/jq -r '.name')
            DOWNLOAD_URL=$(echo "$Q9JSON" | ${pkgs.jq}/bin/jq -r '.download_url')
            FILE_SHA=$(echo "$Q9JSON" | ${pkgs.jq}/bin/jq -r '.sha')

            if [[ "$LATEST_FILE" != "$CURRENT_FILE" ]]; then
              >&2 echo "========================"
              >&2 date
              >&2 echo "NEW QUAD9 UPDATE AVAILABLE!"
              >&2 echo "--------------------"
              >&2 echo "Current file: $ABS_CURRENT_FILE"
              >&2 echo "Latest file : $LATEST_FILE"
              >&2 echo "Download URL: $DOWNLOAD_URL"
              >&2 echo "SHA         : $FILE_SHA"

              MSG="Latest file: $LATEST_FILE\nDownload URL: $DOWNLOAD_URL\n\nClick OK to download the new update"
              export MSG
              export DOWNLOAD_URL
              /usr/bin/osascript -l JavaScript <<'EOF_javascript'
                const app = Application.currentApplication();
                app.includeStandardAdditions = true;
                const msg = app.systemAttribute("MSG");

                // Play an alert sound
                app.beep();

                let response;
                try {
                  // Display the alert
                  response = app.displayAlert("QUAD9 Update available", {
                    message: msg,
                    buttons: ["Cancel", "OK"],
                    defaultButton: "OK"
                  });
                } catch (e) {
                  // Handles user clicking "Cancel" which throws an error in JXA
                  response = { buttonReturned: "Cancel" };
                }

                // Handle user response
                if (response.buttonReturned === "OK") {
                  app.openLocation(app.systemAttribute("DOWNLOAD_URL"));
                }
                void(0);
          EOF_javascript
            else
              ## Validate the SHA of the current file
              CURRENT_SHA=$(${pkgs.git}/bin/git hash-object "$ABS_CURRENT_FILE")
              if [[ "$FILE_SHA" == "$CURRENT_SHA" ]]; then
                echo "========================"
                date
                echo "Quad9 profile is up to date ($ABS_CURRENT_FILE)."
              else
                MSG="Current SHA-1 of Quad9 mobileconfig at $ABS_CURRENT_FILE did not match official SHA-1\nCurrent : $CURRENT_SHA\nOfficial: $FILE_SHA"
                export MSG
                /usr/bin/osascript -l JavaScript <<'EOF_javascript'
                  const app = Application.currentApplication();
                  app.includeStandardAdditions = true;
                  const msg = app.systemAttribute("MSG");

                  // Play an alert sound
                  app.beep();

                  // Display the alert
                  app.displayAlert("Current QUAD9 mobileconfig corrupted!!", {
                    message: msg
                  });
                  void(0);
          EOF_javascript
              fi
            fi
          fi
        ''
      ];
    };
  };

  launchd.user.agents.iroh-ssh-server = lib.mkIf (!isVM) {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.iroh-ssh}/bin/iroh-ssh"
        "server"
        "--persist"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${userInfo.home}/log/org.nixos.user.iroh-ssh-server-Out.log";
      StandardErrorPath = "${userInfo.home}/log/org.nixos.user.iroh-ssh-server-Error.log";
    };
  };

  ## Setting up valkey-server for user
  launchd.user.agents.valkey-private = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.valkey}/bin/valkey-server"
        "--port"
        "${toString valkey_port}"
        "--dir"
        "${valkey_dir}"
        "--appendonly"
        "yes"

        # Ensures updates hit the disk within 1 second
        "--appendfsync"
        "everysec"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${userInfo.home}/log/org.nixos.user.valkey-private-Out.log";
      StandardErrorPath = "${userInfo.home}/log/org.nixos.user.valkey-private-Error.log";
    };
  };

  # Ensure the valkey_dir exists with the proper permissions
  system.activationScripts.postActivation.text = lib.mkAfter ''
    mkdir -p ${valkey_dir}
    chown ${userInfo.name}:staff ${valkey_dir}
    chmod 700 ${valkey_dir}
  '';

  nix.optimise.automatic = true;

  # Setup aliases
  environment.interactiveShellInit =
    # bash
    ''
      alias nex="nix --extra-experimental-features nix-command"
      alias nds="nix --extra-experimental-features nix-command derivation show"
      alias enix="nix --extra-experimental-features nix-command"
      alias nie="nix-instantiate --eval"
      alias drb="sudo -H darwin-rebuild build"
      alias drs="sudo -H darwin-rebuild switch"
      alias drlg="sudo -H darwin-rebuild --list-generations"
      alias valkey-cli="valkey-cli -p \$VALKEY_PORT"
      alias ..="cd .."
      if [[ $- == *i* ]]; then
        L="$HOME/resize-$TERM_PROGRAM.lock"
        if [[ -n "$RESIZE_TERM" ]]; then
          touch $L
          XRSZ_TERM=$RESIZE_TERM
          unset RESIZE_TERM
          LOGF="$HOME/log/''${XRSZ_TERM}Start.log"
          ( (
            trap "rm -f $L" EXIT
            $HOME/.config/jxa/waitapp.js "DisplayLink Manager.app"
            date > $LOGF
            sleep 1
            $HOME/.config/jxa/resize_app.js $XRSZ_TERM >> "$LOGF" 2>&1
            :
          ) >/dev/null 2>&1 & )
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

  # Increase download buffer size to 500 MB
  nix.settings.download-buffer-size = 524288000;

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

  programs.mas = lib.mkIf (!isVM) {
    enable = true;
    packages = pkhostcfg.masPackages;
  };

  #!!!! Removed by nix-darwin commit 1d9f622
  # # For /etc/hosts - do not publicize contents for security reasons
  # networking.hostFiles = [ "/etc/hosts.private" ];

  networking = if builtins.hasAttr "networking" pkhostcfg then pkhostcfg.networking else { };

  # Add sudo_local security services
  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  # configure sudoers to allow %admin to execute the following sudo commands without password
  security.sudo.extraConfig = ''
    %admin  ALL = (ALL) NOPASSWD: /nix/store/*/bin/darwin-rebuild, \
                                  /nix/store/*/bin/nix-channel --add *, \
                                  /nix/store/*/bin/nix-channel --list, \
                                  /nix/store/*/bin/nix-channel --update*, \
                                  /nix/store/*/bin/nix-collect-garbage ^--delete-older-than [0-9]+d$, \
                                  /nix/store/*/bin/nix-store --gc, \
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
      ++ lib.optional (Helpers.pkgInstalled pkgs.brave) (Helpers.getMacBundleAppName pkgs.brave)
      ++ lib.optional (Helpers.brewAppInstalled "brave-browser") "/Applications/Brave Browser.app"
      ++ lib.optional (Helpers.brewAppInstalled "google-chrome") "/Applications/Google Chrome.app"
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

  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      ChallengeResponseAuthentication no
      KbdInteractiveAuthentication no
      PermitRootLogin no
    '';
    hostKeys = [ ]; # Ensure host keys are not generated
  };

  # Enable tailscale only if not in VM
  services.tailscale = {
    enable = !isVM;
  };

  # Disable global system-wide redis
  services.redis.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # Inject the revision directly into system.nixpkgsRevision if
  # the build was called with -I nixpkgs=...
  system.nixpkgsRevision = lib.mkIf (currentRevision != null) currentRevision;

  ids.gids.nixbld = config.machineInfo.buildGroupID;
}
# vim: set ts=2 sw=2 et ft=nix:
