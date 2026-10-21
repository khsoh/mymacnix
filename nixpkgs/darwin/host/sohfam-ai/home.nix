{
  config,
  osConfig,
  pkgs,
  lib,
  user,
  ...
}:
let
  isVM = osConfig.machineInfo.is_vm;
in
{
  home.shellAliases = {
    # Monitoring memory space when hosting 32B+ models locally
    llm-stat = "top -o mem";
    ollama-qwen = "ollama run qwen3.5:32b";
  };

  # Ensure that ~/ai-server directory is created
  home.file."ai-server/podman-compose.yml".text = ''
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
          - OPENAI_API_BASE=http://containers.internal
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

}
