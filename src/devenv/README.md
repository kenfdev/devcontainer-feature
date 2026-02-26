
# devenv (devenv)

A dev container feature that bundles essential terminal-based development tools: tmux, lazygit, neovim (with ripgrep, fd, fzf), and gh.

## Example Usage

```json
"features": {
    "ghcr.io/kenfdev/devcontainer-feature/devenv:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installTmux | Install tmux terminal multiplexer | boolean | true |
| installLazygit | Install lazygit terminal UI for Git | boolean | true |
| installNvim | Install neovim and supporting tools (ripgrep, fd, fzf) | boolean | true |
| tmuxVersion | tmux version to install (e.g., '3.4', 'latest') | string | latest |
| lazygitVersion | lazygit version to install (e.g., '0.40.2', 'latest') | string | latest |
| nvimVersion | neovim version to install (e.g., '0.9.5', 'latest') | string | latest |
| installClaudeCode | Install Claude Code CLI (AI coding assistant) | boolean | true |
| installCodex | Install OpenAI Codex CLI (requires npm) | boolean | true |
| installBeads | Install Beads (AI agent framework by Steve Yegge) | boolean | true |
| installGh | Install GitHub CLI (gh) | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/kenfdev/devcontainer-feature/blob/main/src/devenv/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
