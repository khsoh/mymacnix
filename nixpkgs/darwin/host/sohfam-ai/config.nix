{
  pkgs,
  lib,
  config,
  ...
}:
let
  isVM = config.machineInfo.is_vm;
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
    DOCKER_HOST = "unix:///Users/${config.system.primaryUser}/.local/share/containers/podman/machine/podman.sock";
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
}
