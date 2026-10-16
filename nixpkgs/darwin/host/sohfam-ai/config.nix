{
  pkgs,
  lib,
  config,
  ...
}:
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
    DOCKER_HOST = "unix://${config.home.homeDirectory}/.local/share/containers/podman/machine/podman.sock";
  };

  environment.systemPackages = lib.mkForce (
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
      fastfetch
      btop
      hyperfine

      stow

      ghostty-bin
      _1password-cli # Helpful for deploying secrets
      _1password-gui
      # For installing mas packages
      mas
      # Supporting podman
      podman-compose
    ]
  );

  programs.mas.packages = lib.mkForce {
    "Xcode" = 497799835;
  };

  homebrew.brews = [
    "ollama"
    "podman"
  ];

  homebrew.casks = [
    {
      name = "bazecor";
      greedy = true;
    }
  ];

  ## Postactivation script for sohfam-ai
  postActivationScriptText = ''
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
