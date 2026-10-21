{
  pkgs,
  lib,
  config,
  ...
}:
let
  isVM = config.machineInfo.is_vm;
  userInfo = import ../../userinfo.nix;
  secretsDir = "${userInfo.home}/.config/nixpkgs/secrets";
  pkhostcfg = config.secrets.target.host;
  pkhostDir = "${secretsDir}/host/${pkhostcfg.name}";
in
{
  # Override the default systemPackages
  environment.systemPackages = with pkgs; [
    _1password-cli # Helpful for deploying secrets
    _1password-gui
    # For installing mas packages
    mas
    # Supporting podman
    podman-compose
  ];

  environment.variables = {
    DOCKER_HOST = "unix://${userInfo.home}/.local/share/containers/podman/machine/podman.sock";
  };

  programs.mas = lib.mkForce {
    enable = !isVM;
    packages = {
      "Xcode" = 497799835;
    };
  };

  homebrew.brews = lib.mkForce [
    "mole"
  ];

  homebrew.casks = lib.mkForce [
    "podman-desktop"
    "ollama-app"
  ];

  ## Postactivation script for sohfam-ai
  system.activationScripts.postActivation.text =
    lib.mkAfter
      # bash
      ''
        # shellcheck disable=SC2059
        printf "''${GREEN}''${BOLD}======== Enabling Remote Login (SSH) ========''${ESC}\n"
        /bin/launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true

        # shellcheck disable=SC2059
        printf "''${GREEN}''${BOLD}======== Applying headless hardware crash and power survival defaults ========''${ESC}\n"

        # 1. Force immediate hardware reboot on a Kernel Panic/System Crash
        # (Setting to 1 tells the boot-rom to bypass standard crash screens and reboot instantly)
        /usr/sbin/nvram panic-restart-by-default=%01

        # 2. Automatically power back ON if the Mac mini loses wall power and regains it
        # (Essential for surviving power outages in a server closet)
        /usr/bin/pmset -a autorestart 1

        # 3. Enable screen sharing permissions
        # shellcheck disable=SC2059
        printf "''${GREEN}''${BOLD}======== Enabling screen sharing permissions ========''${ESC}\n"

        ## First, check if screen sharing permissions already enabled
        ss_enabled=0

        while [ "$ss_enabled" -eq 0 ]; do
          while IFS='|' read -r client auth_value; do
            ss_enabled=1
            # shellcheck disable=SC2059
            printf "''${BLUE}''${BOLD}==>''${ESC} Client $client has auth_value $auth_value\n"
            break
          done < <(sqlite3 --readonly "/Library/Application Support/com.apple.TCC/TCC.db" \
            "SELECT client, auth_value FROM access WHERE service='kTCCServiceScreenCapture';")

          if [ "$ss_enabled" -eq 0 ]; then
            CUSERID=$(/usr/bin/id -u "$(/usr/bin/stat -f%Su /dev/console)")

            ## Screen sharing not enabled - prompt user to enable screen sharing
            open "x-apple.systempreferences:com.apple.Sharing-Settings.extension?Services_ScreenSharing"

            ## Block from further execution until OK button is pressed
            /bin/launchctl asuser "$CUSERID" /usr/bin/osascript -e 'display dialog "Press OK after you have enabled Screen Sharing" buttons {"OK"} default button "OK" with title "Enable Screen Sharing Permissions"' >/dev/null 2>&1
          fi
        done
      '';

  # Show all extensions in Finder for sohfam-ai server
  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;

  # For headless server - never sleep
  power.sleep = {
    computer = "never";
    display = "never";
  };

  ## Host-specific info for networking
  networking = {
    hostName = "sohfam-ai";
    localHostName = "sohfam-ai";
    computerName = "sohfam-ai";
  };

  age.secrets.authentik-env = {
    file = /. + "${pkhostDir}/authentik-env.age";

    # path should be a string expression (in quotes), not a path expression
    # IMPORTANT: READ THE DOCUMENTATION on age.secrets.<name>.path
    # NOT specified - so this defaults to /run/agenix/authentik-env

    # The default is true if not specified.  We want to make sure that
    # the "file" (decrypted secret) is symlinked and not generated directly into
    # that location
    # symlink = true;

    # The following are needed to ensure the decrypted secret has the correct permission
    mode = "600";

    # Note that the owner and group attribute are absent from home-manager module
    owner = "${userInfo.name}";
    group = "staff";
  };

  ## Apply home-manager configuration for all users
  home-manager.users."${userInfo.name}" = {
    imports = [ ./home.nix ];
  };

  # --- AUTOMATED CONTAINER INFRASTRUCTURE LAUNCH ---
  launchd.user.agents.podman-compose-startup = lib.mkIf (!isVM) {
    serviceConfig = {
      Label = "org.podman.compose-startup";
      RunAtLoad = true;
      KeepAlive = false;
      WorkingDirectory = "${userInfo.home}/ai-server"; # Your podman-compose folder path
      StandardOutPath = "${userInfo.home}/log/podman-compose-startup.log";
      StandardErrorPath = "${userInfo.home}/log/podman-compose-startup-err.log";
    };
    script = ''
      # 1. Ensure the Podman VM exists. If not, initialize it.
       if ! /opt/homebrew/bin/podman machine inspect podman-machine-default >/dev/null 2>&1; then
         /opt/homebrew/bin/podman machine init --cpus 6 --memory 16384 --disk-size 60
       fi

       # 2. If the machine is stopped, boot it up
       if [ "$(/opt/homebrew/bin/podman machine inspect podman-machine-default --format '{{.State}}')" != "running" ]; then
         /opt/homebrew/bin/podman machine start
       fi

       # 3. Wait until the engine's internal socket bridge responds
       until /opt/homebrew/bin/podman info >/dev/null 2>&1; do
         sleep 2
       done

       # 4. Safely launch the stack
       /run/current-system/sw/bin/podman-compose --env-file ${config.age.secrets.authentik-env.path} up -d
    '';
  };
}
