# tools

A minimal Dev Container Feature that installs terminal development tools.

Installed by default:

- lazygit
- Neovim plus `rg`, `fd`, and `fzf`
- Claude Code
- Codex
- GitHub CLI (`gh`)
- [fdsx](https://github.com/kenfdev/fdsx)
- rtk
- pi

## VS Code Dev Containers

Use this as a normal Dev Container Feature in `.devcontainer/devcontainer.json`.

```jsonc
{
  "name": "my-dev-container",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/kenfdev/devcontainer-feature/tools:1": {}
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
      "installPi": true
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
    INSTALLPI=true

ADD https://raw.githubusercontent.com/kenfdev/devcontainer-feature/main/src/tools/install.sh /tmp/tools-install.sh

RUN chmod +x /tmp/tools-install.sh \
    && /tmp/tools-install.sh \
    && rm -f /tmp/tools-install.sh
```

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
