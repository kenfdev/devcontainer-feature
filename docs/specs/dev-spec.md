# devenv Feature Specification

## Overview

A dev container feature called `devenv` that bundles essential terminal-based development tools: **tmux**, **lazygit**, and **neovim**.

## Installation

```json
"ghcr.io/kenfdev/devcontainer-feature/devenv": {}
```

## Tools Included

| Tool | Description |
|------|-------------|
| tmux | Terminal multiplexer |
| lazygit | Terminal UI for Git |
| neovim | Hyperextensible Vim-based text editor |

When neovim is enabled, the following supporting tools are also installed:
- **ripgrep** (`rg`) - Fast grep alternative, used by telescope.nvim and similar plugins
- **fd** - Fast find alternative, used for file finding
- **fzf** - Fuzzy finder, used by fzf.vim and fzf-lua

## Configuration Options

All options use **camelCase** naming convention.

### Tool Installation Toggles

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installTmux` | boolean | `true` | Install tmux |
| `installLazygit` | boolean | `true` | Install lazygit |
| `installNvim` | boolean | `true` | Install neovim (and supporting tools: ripgrep, fd, fzf) |

### Version Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `tmuxVersion` | string | `"latest"` | tmux version (e.g., `"3.4"`, `"latest"`) |
| `lazygitVersion` | string | `"latest"` | lazygit version (e.g., `"0.40.2"`, `"latest"`) |
| `nvimVersion` | string | `"latest"` | neovim version (e.g., `"0.9.5"`, `"latest"`) |

When set to `"latest"`, the install script queries the GitHub API at build time to fetch the most recent stable release.

## Behavior Details

### Neovim Configuration

Neovim is installed **vanilla** with no pre-configured distribution. Users are expected to bring their own configuration via:
- Mounting dotfiles
- Using a dotfiles repository
- Installing a distribution manually post-build

### Environment Variables

When `installNvim=true`, the following environment variables are set:
- `EDITOR=nvim`
- `VISUAL=nvim`

If `installNvim=false`, these environment variables are **not** set, regardless of any other configuration.

### Installation Path

All binaries are installed to `/usr/local/bin`.

### Architecture Support

The install script auto-detects the system architecture and downloads the appropriate binary:
- `amd64` (x86_64)
- `arm64` (aarch64)

### Error Handling

If a specified version does not exist or download fails:
1. A warning is logged to stderr
2. That specific tool is skipped
3. Installation continues with remaining tools
4. The build does **not** fail

### Installation Source

All tools are installed from **GitHub Releases**:
- tmux: https://github.com/tmux/tmux/releases
- lazygit: https://github.com/jesseduffield/lazygit/releases
- neovim: https://github.com/neovim/neovim/releases
- ripgrep: https://github.com/BurntSushi/ripgrep/releases
- fd: https://github.com/sharkdp/fd/releases
- fzf: https://github.com/junegunn/fzf/releases

### tmux Details

- Installed as a standalone binary
- No TPM (Tmux Plugin Manager) included
- Users who want plugin management can set up TPM themselves

## Supported Base Images

The feature must support all major distros:

| Distro | Package Manager | C Library | Notes |
|--------|-----------------|-----------|-------|
| Debian | apt | glibc | Primary target |
| Ubuntu | apt | glibc | Primary target |
| Alpine | apk | musl | Requires musl-compatible binaries |
| Fedora | dnf | glibc | |

The install script must detect the base image and handle:
- Different package managers for installing build dependencies (if needed)
- glibc vs musl binary selection for Alpine

## Dependencies

This feature has **no external feature dependencies** (does not depend on `common-utils` or other features).

## Output Verbosity

- No verbosity option exposed
- Install script outputs moderate information: key steps and any warnings
- Does not flood the build log with verbose download/extraction details

## Testing

### Test Strategy

Tests verify **binary existence only**:
- Confirm each tool binary exists at expected path
- Confirm each binary is executable
- Tests do not verify version matching or functional behavior

### Test Scenarios

1. **Default installation** - All tools with latest versions
2. **Selective installation** - Only tmux enabled
3. **Selective installation** - Only lazygit enabled
4. **Selective installation** - Only nvim enabled
5. **All disabled** - No tools installed (edge case)
6. **Specific versions** - Pin specific versions for each tool

## Example Configurations

### Minimal (all defaults)

```json
"features": {
  "ghcr.io/kenfdev/devcontainer-feature/devenv": {}
}
```

### Only lazygit

```json
"features": {
  "ghcr.io/kenfdev/devcontainer-feature/devenv": {
    "installTmux": false,
    "installNvim": false
  }
}
```

### Pinned versions

```json
"features": {
  "ghcr.io/kenfdev/devcontainer-feature/devenv": {
    "tmuxVersion": "3.4",
    "lazygitVersion": "0.40.2",
    "nvimVersion": "0.9.5"
  }
}
```

### Neovim only with specific version

```json
"features": {
  "ghcr.io/kenfdev/devcontainer-feature/devenv": {
    "installTmux": false,
    "installLazygit": false,
    "nvimVersion": "0.10.0"
  }
}
```

## File Structure

```
src/devenv/
├── devcontainer-feature.json    # Feature metadata and options schema
├── install.sh                   # Main installation script
└── README.md                    # Auto-generated documentation

test/devenv/
├── scenarios.json               # Test scenario definitions
├── test.sh                      # Auto-generated test script
├── default.sh                   # Default scenario test
├── tmux-only.sh                 # tmux-only scenario test
├── lazygit-only.sh              # lazygit-only scenario test
├── nvim-only.sh                 # nvim-only scenario test
└── pinned-versions.sh           # Pinned versions scenario test
```

## Implementation Notes

### GitHub API for Latest Version

To fetch the latest version, query:
```
https://api.github.com/repos/{owner}/{repo}/releases/latest
```

Parse the `tag_name` field. Handle rate limiting gracefully (GitHub allows 60 requests/hour for unauthenticated requests).

### Alpine/musl Handling

Some tools provide musl-specific builds:
- neovim: Use AppImage or build from source
- ripgrep: Provides musl builds
- fd: Provides musl builds
- fzf: Go binary, works on musl
- lazygit: Go binary, works on musl
- tmux: May need to build from source on Alpine

### Binary Verification

After download, verify:
1. File exists
2. File is executable
3. Binary runs without immediate error (optional sanity check)
