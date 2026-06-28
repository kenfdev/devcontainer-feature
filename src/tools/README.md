# tools

A minimal Dev Container Feature that installs terminal development tools and optional Tailscale SSH access.

Installed by default:

- lazygit
- Neovim plus `rg`, `fd`, and `fzf`
- Claude Code
- Codex
- GitHub CLI (`gh`)
- [fdsx](https://github.com/kenfdev/fdsx)
- rtk
- pi
- Tailscale

## VS Code Dev Containers

Use this as a normal Dev Container Feature in `.devcontainer/devcontainer.json`.

```jsonc
{
  "name": "my-dev-container",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/kenfdev/devcontainer-feature/tools:1": {}
  },
  "containerEnv": {
    "TS_AUTH_KEY": "${localEnv:TS_AUTH_KEY}",
    "TS_HOSTNAME": "dev-myrepo",
    "TS_TAG": "tag:dev-container"
  }
}
```

To customize installed tools:

```jsonc
{
  "name": "my-dev-container",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/kenfdev/devcontainer-feature/tools:1": {
      "installLazygit": true,
      "lazygitVersion": "latest",
      "installNvim": true,
      "nvimVersion": "latest",
      "installClaudeCode": true,
      "installCodex": true,
      "installGh": true,
      "installFdsx": true,
      "installRtk": true,
      "installPi": true,
      "installTailscale": true
    }
  }
}
```

After changing `devcontainer.json`, run **Dev Containers: Rebuild Container** in VS Code.

## Raw Dockerfiles

Dev Container Features can be applied to plain Dockerfiles by using the Dev Container CLI to generate a resolved Dockerfile.

Create a `devcontainer.json` next to your Dockerfile:

```jsonc
{
  "name": "tools-image",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "features": {
    "ghcr.io/kenfdev/devcontainer-feature/tools:1": {}
  }
}
```

Then build it with the Dev Container CLI:

```bash
npm install -g @devcontainers/cli
devcontainer build --workspace-folder .
```

For a Dockerfile-only flow, download this feature's `install.sh` into your image and run it as root. Feature options are passed as uppercase environment variables without punctuation.

```dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV INSTALLLAZYGIT=true \
    INSTALLNVIM=true \
    INSTALLCLAUDECODE=true \
    INSTALLCODEX=true \
    INSTALLGH=true \
    INSTALLFDSX=true \
    INSTALLRTK=true \
    INSTALLPI=true \
    INSTALLTAILSCALE=false

ADD https://raw.githubusercontent.com/kenfdev/devcontainer-feature/main/src/tools/install.sh /tmp/tools-install.sh

RUN chmod +x /tmp/tools-install.sh \
    && /tmp/tools-install.sh \
    && rm -f /tmp/tools-install.sh
```

For Dockerfile-only usage with Tailscale enabled, clone or copy the feature directory so `install.sh` can copy `tailscale-entrypoint.sh` from the same directory:

```Dockerfile
FROM node:22-bookworm

ARG FEATURE_REF=v1.3.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && git clone --depth 1 --branch "${FEATURE_REF}" \
      https://github.com/kenfdev/devcontainer-feature.git /tmp/features \
 && /tmp/features/src/tools/install.sh \
 && rm -rf /tmp/features \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/local/bin/tailscale-entrypoint.sh"]
CMD ["sleep", "infinity"]
```

Docker Compose example:

```yaml
services:
  dev:
    build: .
    hostname: dev-myrepo
    environment:
      TS_AUTH_KEY: ${TS_AUTH_KEY}
      TS_HOSTNAME: dev-myrepo
      TS_TAG: tag:dev-container
      TS_ENABLE_SSH: "true"
      TS_RESET_ON_AUTH_FAILURE: "true"
    cap_add:
      - NET_ADMIN
      - NET_RAW
      - MKNOD
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - tailscale-state:/var/lib/tailscale
      - .:/workspace
    working_dir: /workspace
    command: sleep infinity

volumes:
  tailscale-state:
```

1Password CLI example:

```env
TS_AUTH_KEY=op://Private/Tailscale Dev Container Auth Key/credential
```

```bash
op run --env-file .env -- docker compose up -d
```

`TS_AUTH_KEY` and `TS_AUTHKEY` are unset inside the entrypoint after being read. Docker/container metadata may still retain environment values, so use runtime secret injection and do not bake secrets into a Dockerfile. A reusable, non-ephemeral, pre-approved, tagged auth key is expected; the recommended tag is `tag:dev-container`. Configure Tailnet ACLs so devices tagged `tag:dev-container` cannot move laterally to other Tailnet devices unless explicitly required.

## Options

| Option | Description | Type | Default |
| --- | --- | --- | --- |
| `installLazygit` | Install lazygit terminal UI for Git | boolean | `true` |
| `installNvim` | Install neovim and supporting tools (`ripgrep`, `fd`, `fzf`) | boolean | `true` |
| `lazygitVersion` | lazygit version to install, for example `0.40.2` or `latest` | string | `latest` |
| `nvimVersion` | Neovim version to install, for example `v0.10.4` or `latest` | string | `latest` |
| `installClaudeCode` | Install Claude Code CLI | boolean | `true` |
| `installCodex` | Install OpenAI Codex CLI | boolean | `true` |
| `installGh` | Install GitHub CLI (`gh`) | boolean | `true` |
| `installFdsx` | Install [fdsx](https://github.com/kenfdev/fdsx) | boolean | `true` |
| `installRtk` | Install rtk | boolean | `true` |
| `installPi` | Install pi coding agent | boolean | `true` |
| `installTailscale` | Install Tailscale and configure the tools entrypoint for Tailscale SSH | boolean | `true` |
