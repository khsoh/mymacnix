{
  pkgs,
  lib,
  config,
  ...
}:
let
  isVM = config.machineInfo.is_vm;
  userInfo = import ./userinfo.nix;
  secretsDir = "${userInfo.home}/.config/nixpkgs/secrets";
  pkhostcfg = config.secrets.target.host;
  pkhostDir = "${secretsDir}/host/${pkhostcfg.name}";
in
{
  environment.interactiveShellInit = ''
    alias docker="podman"
    alias docker-compose="podman-compose"

    # Monitoring memory space when hosting 32B+ models locally
    alias llm-stat="top -o mem"
    alias ollama-qwen="ollama run qwen3.5:32b"
  '';

  environment.variables = {
    # Dynamically injects the correct user home path (e.g., /Users/yourname)
    DOCKER_HOST = "unix://${userInfo.home}/.local/share/containers/podman/machine/podman.sock";
  };

  # Override the default systemPackages
  environment.systemPackages = with pkgs; [
    _1password-cli # Helpful for deploying secrets
    _1password-gui
    # For installing mas packages
    mas
    # Supporting podman
    podman-compose
  ];

  programs.mas = lib.mkForce {
    enable = !isVM;
    packages = {
      "Xcode" = 497799835;
    };
  };

  homebrew.brews = lib.mkForce [
    "ollama"
    "podman"
    "mole"
  ];

  homebrew.casks = lib.mkForce [
  ];

  ## Postactivation script for sohfam-ai
  system.activationScripts.postActivation.text = ''
    echo "Ensuring Remote Login (SSH) is enabled..."
    /bin/launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true

    echo "Applying headless hardware crash and power survival defaults..."

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

  age.secrets.authentik-env = lib.mkIf {
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

  # Ensure that ~/ai-server directory is created
  home-manager.users."${userInfo.name}".home.file."ai-server/.keep".text = "";

  # --- AUTOMATED CONTAINER INFRASTRUCTURE LAUNCH ---
  launchd.user.agents.podman-compose-startup = {
    serviceConfig = {
      Label = "org.podman.compose-startup";
      RunAtLoad = true;
      KeepAlive = false;
      WorkingDirectory = "${userInfo.home}/ai-server"; # Your docker-compose/podman-compose folder path
      StandardOutPath = "${userInfo.home}/log/podman-compose-startup.log";
      StandardErrorPath = "${userInfo.home}/log/podman-compose-startup-err.log";
    };
    script = ''
      # 1. Wait until the background Podman Linux VM finishes booting completely
      until /opt/homebrew/bin/podman info >/dev/null 2>&1; do
        sleep 2
      done

      # 2. Start the stack referencing absolute binary paths
      /run/current-system/sw/bin/podman-compose --env-file ${config.age.secrets.authentik-env.path} up -d
    '';
  };
}
