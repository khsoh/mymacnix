{
  pkgs,
  lib,
  config,
  userInfo,
  ...
}:
let
  isVM = config.machineInfo.is_vm;
  aiHome = "${userInfo.home}/ai-server";
  secretsDir = "${userInfo.home}/.config/nixpkgs/secrets";
  pkhostcfg = config.secrets.target.host;
  pkhostDir = "${secretsDir}/host/${pkhostcfg.name}";
  brewPrefix = config.homebrew.prefix;
  ollamaBin = "${brewPrefix}/bin/ollama";
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
    {
      name = "ollama-binary";
      postinstall = ''
        /usr/bin/xattr -dr com.apple.quarantine \"${brewPrefix}/Caskroom/ollama-binary\" 2>/dev/null || true
      '';

    }
  ];

  ## Postactivation script for sohfam-ai
  system.activationScripts.postActivation.text =
    lib.mkBefore
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

  # --- ollama launch agent
  launchd.user.agents.ollama = {
    serviceConfig = {
      Label = "org.nixos.user.ollama";
      ProgramArguments = [
        ollamaBin
        "serve"
      ];
      EnvironmentVariables = {
        OLLAMA_HOST = "127.0.0.1:11434";
        OLLAMA_MODELS = "${userInfo.home}/.ollama/models";
        OLLAMA_KEEP_ALIVE = "-1";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_FLASH_ATTENTION = "1";
      };
      WorkingDirectory = aiHome;
      KeepAlive = true;
      RunAtLoad = true;
      ThrottleInterval = 30;
      StandardOutPath = "${userInfo.home}/log/ollama.out.log";
      StandardErrorPath = "${userInfo.home}/log/ollama.err.log";
    };
  };

  # --- AUTOMATED CONTAINER INFRASTRUCTURE LAUNCH ---
  launchd.user.agents.podman-compose-startup = lib.mkIf (!isVM) {
    serviceConfig = {
      Label = "org.podman.compose-startup";
      RunAtLoad = true;
      KeepAlive = false;
      WorkingDirectory = "${aiHome}"; # Your podman-compose folder path
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
