# Dev Container Features

Custom [Dev Container Features](https://containers.dev/features) published to GitHub Container Registry.

## Available Features

- [`devenv`](./src/devenv) - terminal-focused development environment with tmux, lazygit, Neovim, GitHub CLI, and AI coding CLIs.
- [`tools`](./src/tools) - minimal terminal-focused tool bundle with lazygit, Neovim, GitHub CLI, AI coding CLIs, C/C++ build tools, Tailscale access, and optional normal SSH access.
- [`tig`](./src/tig) - installs [`tig`](https://jonas.github.io/tig/), the text-mode interface for Git.

## `devenv`

A dev container feature that bundles essential terminal-based development tools: tmux, lazygit, neovim (with ripgrep, fd, fzf), gh, Claude Code, Codex, opencode, fdsx, rtk, and pi.

### Example Usage

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/kenfdev/devcontainer-feature/devenv:1": {}
  }
}
```

Disable individual tools or pin supported tool versions as needed:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/kenfdev/devcontainer-feature/devenv:1": {
      "installTmux": true,
      "tmuxVersion": "3.4",
      "installLazygit": true,
      "lazygitVersion": "0.40.2",
      "installNvim": true,
      "nvimVersion": "0.9.5",
      "installClaudeCode": true,
      "installCodex": true,
      "installGh": true,
      "installOpencode": false,
      "installFdsx": true,
      "installRtk": true,
      "installPi": true
    }
  }
}
```

### Options

| Option | Description | Type | Default |
| --- | --- | --- | --- |
| `installTmux` | Install tmux terminal multiplexer | boolean | `false` |
| `installLazygit` | Install lazygit terminal UI for Git | boolean | `true` |
| `installNvim` | Install neovim and supporting tools (ripgrep, fd, fzf) | boolean | `true` |
| `tmuxVersion` | tmux version to install (e.g., `3.4`, `latest`) | string | `latest` |
| `lazygitVersion` | lazygit version to install (e.g., `0.40.2`, `latest`) | string | `latest` |
| `nvimVersion` | neovim version to install (e.g., `0.9.5`, `latest`) | string | `latest` |
| `installClaudeCode` | Install Claude Code CLI (AI coding assistant) | boolean | `true` |
| `installCodex` | Install OpenAI Codex CLI (requires npm) | boolean | `true` |
| `installGh` | Install GitHub CLI (gh) | boolean | `true` |
| `installOpencode` | Install opencode (AI coding assistant) | boolean | `false` |
| `installFdsx` | Install fdsx | boolean | `true` |
| `installRtk` | Install rtk (Rust Token Killer - token-optimized CLI proxy) | boolean | `true` |
| `installPi` | Install pi coding agent | boolean | `true` |

## `tools`

A minimal dev container feature that bundles terminal-based development tools: lazygit, neovim (with ripgrep, fd, fzf), gh, Claude Code, Codex, fdsx, rtk, pi, C/C++ build tools, Tailscale access, and an optional OpenSSH server for normal SSH clients.

### Example Usage

```jsonc
{
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

Disable individual tools or pin supported tool versions as needed:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/kenfdev/devcontainer-feature/tools:1": {
      "installLazygit": true,
      "lazygitVersion": "0.40.2",
      "installNvim": true,
      "nvimVersion": "0.9.5",
      "installClaudeCode": true,
      "installCodex": true,
      "installGh": true,
      "installFdsx": true,
      "installRtk": true,
      "installPi": true,
      "installTailscale": true,
      "installSshd": true,
      "installBuildTools": true
    }
  }
}
```

### Options

| Option | Description | Type | Default |
| --- | --- | --- | --- |
| `installLazygit` | Install lazygit terminal UI for Git | boolean | `true` |
| `installNvim` | Install neovim and supporting tools (ripgrep, fd, fzf) | boolean | `true` |
| `lazygitVersion` | lazygit version to install (e.g., `0.40.2`, `latest`) | string | `latest` |
| `nvimVersion` | neovim version to install (e.g., `0.9.5`, `latest`) | string | `latest` |
| `installClaudeCode` | Install Claude Code CLI (AI coding assistant) | boolean | `true` |
| `installCodex` | Install OpenAI Codex CLI (requires npm) | boolean | `true` |
| `installGh` | Install GitHub CLI (gh) | boolean | `true` |
| `installFdsx` | Install fdsx | boolean | `true` |
| `installRtk` | Install rtk (Rust Token Killer - token-optimized CLI proxy) | boolean | `true` |
| `installPi` | Install pi coding agent | boolean | `true` |
| `installTailscale` | Install Tailscale and configure the tools entrypoint for Tailscale SSH | boolean | `true` |
| `installSshd` | Install and start OpenSSH server for normal SSH access | boolean | `true` |
| `installBuildTools` | Install python3, make, and a C++ compiler when missing | boolean | `true` |

The `tools` feature metadata sets `/usr/local/bin/tailscale-entrypoint.sh` as the entrypoint and adds `NET_ADMIN`, `NET_RAW`, and `MKNOD`. It persists Tailscale state in `/var/lib/tailscale` and SSH host keys in `/var/lib/ssh-host-keys`. For normal SSH access, provide a public key with `SSH_AUTHORIZED_KEYS` or `SSH_AUTHORIZED_KEYS_FILE`. For Dockerfile-only usage, set `INSTALLTAILSCALE=false`, `INSTALLSSHD=false`, or `INSTALLBUILDTOOLS=false` to skip specific service or build-tool installation.

## `tig`

### Example Usage

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/kenfdev/devcontainer-feature/tig:1": {}
  }
}
```

### Options

| Option | Description | Type | Default |
| --- | --- | --- | --- |
| `customprefix` | The prefix to use where to install tig | string | `/usr/local` |

## Development

```bash
# Run autogenerated tests for a feature
devcontainer features test --skip-scenarios -f devenv -i mcr.microsoft.com/devcontainers/base:ubuntu .

# Run scenario-based tests only
devcontainer features test -f devenv --skip-autogenerated --skip-duplicated .

# Run tests for the tools feature
devcontainer features test -f tools --skip-autogenerated --skip-duplicated .

# Run full test suite
devcontainer features test
```

Feature metadata lives in `src/<feature>/devcontainer-feature.json`, install scripts live in `src/<feature>/install.sh`, and feature README files are generated from metadata.
