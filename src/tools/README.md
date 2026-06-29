
# tools (tools)

A minimal dev container feature that bundles terminal-based development tools and optional Tailscale SSH access.

## Example Usage

```json
"features": {
    "ghcr.io/kenfdev/devcontainer-feature/tools:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installLazygit | Install lazygit terminal UI for Git | boolean | true |
| installNvim | Install neovim and supporting tools (ripgrep, fd, fzf) | boolean | true |
| lazygitVersion | lazygit version to install (e.g., '0.40.2', 'latest') | string | latest |
| nvimVersion | neovim version to install (e.g., '0.9.5', 'latest') | string | latest |
| installClaudeCode | Install Claude Code CLI (AI coding assistant) | boolean | true |
| installCodex | Install OpenAI Codex CLI (requires npm) | boolean | true |
| installGh | Install GitHub CLI (gh) | boolean | true |
| installFdsx | Install fdsx (fast data serialization tool) | boolean | true |
| installRtk | Install rtk (Rust Token Killer - token-optimized CLI proxy) | boolean | true |
| installPi | Install pi coding agent | boolean | true |
| installTailscale | Install Tailscale and configure the tools entrypoint for Tailscale SSH | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/kenfdev/devcontainer-feature/blob/main/src/tools/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
