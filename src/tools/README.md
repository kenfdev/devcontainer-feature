# tools (tools)

A minimal dev container feature that bundles terminal-based development tools: lazygit, neovim (with ripgrep, fd, fzf), Claude Code, Codex, gh, [fdsx](https://github.com/kenfdev/fdsx), rtk, pi, and SSH access.

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
| installFdsx | Install [fdsx](https://github.com/kenfdev/fdsx) | boolean | true |
| installRtk | Install rtk (Rust Token Killer - token-optimized CLI proxy) | boolean | true |
| installPi | Install pi coding agent | boolean | true |
| installSsh | Install and configure OpenSSH server for public-key container access | boolean | true |
| sshUser | User allowed to connect over SSH. Created if missing. | string | dev |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/kenfdev/devcontainer-feature/blob/main/src/tools/devcontainer-feature.json). Add additional notes to a `NOTES.md`._
