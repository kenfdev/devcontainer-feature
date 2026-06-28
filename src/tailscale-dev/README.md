# Tailscale Dev Container

Installs Tailscale in a Debian/Ubuntu development container and configures `/usr/local/bin/tailscale-entrypoint.sh` as the container entrypoint.

This feature is intended for Tailscale SSH access to dev containers. Runtime auth keys must be passed through environment variables such as `TS_AUTH_KEY`; do not bake secrets into a Dockerfile.

## Dev Container

```jsonc
{
  "features": {
    "ghcr.io/kenfdev/devcontainer-feature/tailscale-dev:0.1.0": {}
  },
  "containerEnv": {
    "TS_AUTH_KEY": "${localEnv:TS_AUTH_KEY}",
    "TS_HOSTNAME": "dev-myrepo",
    "TS_TAG": "tag:dev-container"
  }
}
```

The feature metadata sets:

- `entrypoint`: `/usr/local/bin/tailscale-entrypoint.sh`
- `capAdd`: `NET_ADMIN`, `NET_RAW`, `MKNOD`
- volume mount: `/var/lib/tailscale`
- default env: `TS_STATE_DIR=/var/lib/tailscale`, `TS_ENABLE_SSH=true`, `TS_TAG=tag:dev-container`

## Dockerfile

When using plain Docker or Docker Compose, `devcontainer-feature.json` metadata is not applied. Set `ENTRYPOINT`, capabilities, devices, volumes, and environment explicitly.

```Dockerfile
FROM node:22-bookworm

ARG TAILSCALE_FEATURE_REF=v0.1.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && git clone --depth 1 --branch "${TAILSCALE_FEATURE_REF}" \
      https://github.com/kenfdev/devcontainer-feature.git /tmp/features \
 && /tmp/features/src/tailscale-dev/install.sh \
 && rm -rf /tmp/features \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/local/bin/tailscale-entrypoint.sh"]
CMD ["sleep", "infinity"]
```

## Docker Compose

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

## 1Password CLI

```env
TS_AUTH_KEY=op://Private/Tailscale Dev Container Auth Key/credential
```

```bash
op run --env-file .env -- docker compose up -d
```

## Runtime Environment

| Variable | Default | Description |
| --- | --- | --- |
| `TS_AUTH_KEY` / `TS_AUTHKEY` | empty | Auth key used when the container is not already authenticated. |
| `TS_STATE_DIR` | `/var/lib/tailscale` | Persistent Tailscale state directory. |
| `TS_HOSTNAME` | `hostname` output | Hostname passed to `tailscale up --hostname`. |
| `TS_TAG` | `tag:dev-container` | Tags passed to `tailscale up --advertise-tags`. |
| `TS_ENABLE_SSH` | `true` | Adds `--ssh` when set to `true`. |
| `TS_ACCEPT_ROUTES` | `false` | Adds `--accept-routes` when set to `true`. |
| `TS_EXTRA_ARGS` | empty | Extra whitespace-separated arguments appended to `tailscale up`. |
| `TS_RESET_ON_AUTH_FAILURE` | `false` | Runs `tailscale logout`, clears state, and retries once after auth failure. |

`TS_AUTH_KEY` and `TS_AUTHKEY` are unset inside the entrypoint after being read. Docker/container metadata may still retain environment values, so use runtime secret injection and avoid long-lived broad credentials.

Use a reusable, non-ephemeral, pre-approved, tagged auth key. The recommended tag is `tag:dev-container`. Configure Tailnet ACLs so devices tagged `tag:dev-container` cannot move laterally to other Tailnet devices unless explicitly required.
