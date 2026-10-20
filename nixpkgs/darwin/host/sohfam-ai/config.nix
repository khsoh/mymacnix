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
  environment.interactiveShellInit = ''
    # Monitoring memory space when hosting 32B+ models locally
    alias llm-stat="top -o mem"
    alias ollama-qwen="ollama run qwen3.5:32b"
  '';

  # Override the default systemPackages
  environment.systemPackages = with pkgs; [
    _1password-cli # Helpful for deploying secrets
    _1password-gui
    # For installing mas packages
    mas
    # Supporting docker
    docker-compose
  ];

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
    "docker-desktop"
    "ollama-app"
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

  # Ensure that ~/ai-server directory is created
  home-manager.users."${userInfo.name}".home.file."ai-server/docker-compose.yml".text = ''
    version: '3.8'

    services:
      # --- AUTHENTIK CORE SERVICES ---
      authentik-postgresql:
        image: postgres:16-alpine
        restart: unless-stopped
        volumes:
          - database:/var/lib/postgresql/data
        environment:
          POSTGRES_PASSWORD: ''${PG_PASS:?error}
          POSTGRES_USER: ''${PG_USER:?error}
          POSTGRES_DB: ''${PG_DB:?error}

      authentik-redis:
        image: redis:7-alpine
        restart: unless-stopped
        volumes:
          - redis:/data

      authentik-server:
        image: ghcr.io/goauthentik/server:2026.8.2
        restart: unless-stopped
        command: server
        environment:
          AUTHENTIK_REDIS__HOST: authentik-redis
          AUTHENTIK_POSTGRESQL__HOST: authentik-postgresql
          AUTHENTIK_POSTGRESQL__USER: ''${PG_USER:?error}
          AUTHENTIK_POSTGRESQL__NAME: ''${PG_DB:?error}
          AUTHENTIK_POSTGRESQL__PASSWORD: ''${PG_PASS:?error}
          AUTHENTIK_SECRET_KEY: ''${AUTHENTIK_SECRET_KEY:?error}
        volumes:
          - ./authentik/media:/media
          - ./authentik/custom-templates:/templates
        ports:
          - "9000:9000"
          - "9443:9443"
        depends_on:
          - authentik-postgresql
          - authentik-redis

      authentik-worker:
        image: ghcr.io/goauthentik/server:2026.8.2
        restart: unless-stopped
        command: worker
        environment:
          AUTHENTIK_REDIS__HOST: authentik-redis
          AUTHENTIK_POSTGRESQL__HOST: authentik-postgresql
          AUTHENTIK_POSTGRESQL__USER: ''${PG_USER:?error}
          AUTHENTIK_POSTGRESQL__NAME: ''${PG_DB:?error}
          AUTHENTIK_POSTGRESQL__PASSWORD: ''${PG_PASS:?error}
          AUTHENTIK_SECRET_KEY: ''${AUTHENTIK_SECRET_KEY:?error}
        volumes:
          - ./authentik/media:/media
          - ./authentik/certs:/certs
          - ./authentik/custom-templates:/templates
        depends_on:
          - authentik-postgresql
          - authentik-redis

      # --- PRESENTON ---
      presenton:
        image: ghcr.io/presenton/presenton:latest
        restart: unless-stopped
        ports:
          - "5000:80"
        volumes:
          - ./presenton_data:/app/user_data
        environment:
          - OPENAI_API_BASE=http://containers.internal # Routes Presenton to host's Ollama
          - OPENAI_API_KEY=ollama # Dummy string required by OpenAI-compatible endpoints
        extra_hosts:
          - "host.containers.internal:host-gateway"

      # --- AUTHENTIK PROXY OUTPOST ---
      # Protects Presenton & Ollama endpoints with your Google SSO policy
      authentik-proxy:
        image: ghcr.io/goauthentik/proxy:latest
        restart: unless-stopped
        ports:
          - "80:9000"
          - "443:9443"
        environment:
          AUTHENTIK_HOST: http://authentik-server:9000
          AUTHENTIK_INSECURE: "true"
          AUTHENTIK_TOKEN: ''${OUTPOST_TOKEN:?error}

    volumes:
      database:
        driver: local
      redis:
        driver: local
  '';

  # --- AUTOMATED CONTAINER INFRASTRUCTURE LAUNCH ---
  launchd.user.agents.docker-compose-startup = {
    serviceConfig = {
      Label = "org.docker.compose-startup";
      RunAtLoad = true;
      KeepAlive = false;
      WorkingDirectory = "${userInfo.home}/ai-server"; # Your docker-compose folder path
      StandardOutPath = "${userInfo.home}/log/docker-compose-startup.log";
      StandardErrorPath = "${userInfo.home}/log/docker-compose-startup-err.log";
    };
    script = ''
      echo "Initializing headless Docker virtualization platform engine..."
      # Opens Docker Desktop silently without spawning visual graphical interface layers
      open -a "Docker" --args --background

      # Polling sequence: block until the local system engine API socket becomes responsive
      until /Applications/Docker.app/Contents/Resources/bin/docker info >/dev/null 2>&1; do
        sleep 3
      done

      echo "Docker socket responsive. Mounting container stack..."
      /run/current-system/sw/bin/docker-compose --env-file ${config.age.secrets.authentik-env.path} -f ${userInfo.home}/ai-server/docker-compose.yml up -d
    '';
  };
}
