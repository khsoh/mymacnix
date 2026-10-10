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
builtins.seq [ osConfig pkgs ] {
  usermap = {
    khsoh = "khsoh";
  };

  onepassword = {
    enable = true;
  };

  agecfg = {
    OPURI = "op://sohfam-ai-Secrets/Host age secret key/notesPlain";
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
    "ollama"
    "podman"
  ];

  hostbrew.casks = [
    {
      name = "bazecor";
      greedy = true;
    }
  ];

  masPackages = {
  };

  # System packages to install in sohfam-ai server
  hostPackages = with pkgs; [
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
  ];

  ## Host-specific info for networking
  networking = {
    hostName = "sohfam-ai";
    localHostName = "sohfam-ai";
    computerName = "sohfam-ai";
  };
}
# vim: set ts=2 sw=2 et ft=nix:
