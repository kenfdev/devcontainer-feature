#!/bin/bash
set -e

# devenv feature install script
# Installs tmux, lazygit, neovim (with supporting tools: ripgrep, fd, fzf), gh,
# Claude Code, Codex, opencode, fdsx, rtk, and pi

# Options (passed as environment variables)
INSTALL_TMUX="${INSTALLTMUX:-true}"
INSTALL_LAZYGIT="${INSTALLLAZYGIT:-true}"
INSTALL_NVIM="${INSTALLNVIM:-true}"
INSTALL_CLAUDE_CODE="${INSTALLCLAUDECODE:-true}"
INSTALL_CODEX="${INSTALLCODEX:-true}"
INSTALL_GH="${INSTALLGH:-true}"
INSTALL_OPENCODE="${INSTALLOPENCODE:-false}"
INSTALL_FDSX="${INSTALLFDSX:-true}"
INSTALL_RTK="${INSTALLRTK:-true}"
INSTALL_PI="${INSTALLPI:-true}"
TMUX_VERSION="${TMUXVERSION:-latest}"
LAZYGIT_VERSION="${LAZYGITVERSION:-latest}"
NVIM_VERSION="${NVIMVERSION:-latest}"

# Installation target
INSTALL_DIR="/usr/local/bin"

# Detect remote user (provided by devcontainer CLI)
REMOTE_USER="${_REMOTE_USER:-root}"
REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/root}"

# Detect architecture
detect_architecture() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "WARNING: Unsupported architecture: $arch" >&2
            echo "unknown"
            ;;
    esac
}

ARCH=$(detect_architecture)
echo "Detected architecture: $ARCH"

# Helper function to get latest release version from GitHub
get_latest_version() {
    local repo="$1"
    local response
    local version

    if ! response=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest"); then
        echo "WARNING: Failed to fetch latest release metadata for ${repo}" >&2
        return 1
    fi

    version=$(printf '%s\n' "$response" | awk -F'"' '/^[[:space:]]*"tag_name"[[:space:]]*:/ { print $4; exit }')
    if [ -z "$version" ]; then
        echo "WARNING: Could not parse latest release version for ${repo}" >&2
        return 1
    fi

    echo "$version"
}

# Helper function to download a file with error handling
download_file() {
    local url="$1"
    local output="$2"

    if ! curl -fsSL "$url" -o "$output"; then
        echo "WARNING: Failed to download from $url" >&2
        return 1
    fi
    return 0
}

# Install build dependencies (curl, tar, gzip are typically needed)
install_dependencies() {
    echo "Installing build dependencies..."
    if command -v apt-get &>/dev/null; then
        apt-get update
        apt-get install -y --no-install-recommends curl ca-certificates tar gzip xz-utils
    elif command -v apk &>/dev/null; then
        apk add --no-cache curl ca-certificates tar gzip xz
    elif command -v dnf &>/dev/null; then
        dnf install -y curl ca-certificates tar gzip xz
    fi
}

# Install tmux build dependencies
install_tmux_build_deps() {
    echo "Installing tmux build dependencies..."
    if command -v apt-get &>/dev/null; then
        apt-get install -y --no-install-recommends build-essential libevent-dev libncurses-dev bison pkg-config
    elif command -v apk &>/dev/null; then
        apk add --no-cache build-base libevent-dev ncurses-dev bison pkgconf
    elif command -v dnf &>/dev/null; then
        dnf install -y gcc make libevent-devel ncurses-devel bison pkgconfig
    else
        echo "WARNING: Unknown package manager, cannot install tmux build dependencies" >&2
        return 1
    fi
    return 0
}

# Install tmux from GitHub Releases (builds from source)
install_tmux() {
    if [ "$INSTALL_TMUX" != "true" ]; then
        echo "Skipping tmux installation (disabled)"
        return 0
    fi

    echo "Installing tmux..."
    local version="$TMUX_VERSION"

    if [ "$version" = "latest" ]; then
        version=$(get_latest_version "tmux/tmux")
    fi

    if [ -z "$version" ]; then
        echo "WARNING: Could not determine tmux version, skipping" >&2
        return 0
    fi

    # Strip leading 'v' if present (tmux versions don't have 'v' prefix typically)
    local version_num="${version#v}"
    echo "tmux version: $version_num"

    # Install build dependencies
    if ! install_tmux_build_deps; then
        echo "WARNING: Failed to install tmux build dependencies, skipping tmux" >&2
        return 0
    fi

    local url="https://github.com/tmux/tmux/releases/download/${version_num}/tmux-${version_num}.tar.gz"
    local tmpdir
    tmpdir=$(mktemp -d)

    if ! download_file "$url" "$tmpdir/tmux.tar.gz"; then
        echo "WARNING: Failed to download tmux, skipping" >&2
        rm -rf "$tmpdir"
        return 0
    fi

    # Extract and build
    tar -xzf "$tmpdir/tmux.tar.gz" -C "$tmpdir"
    cd "$tmpdir/tmux-${version_num}" || {
        echo "WARNING: Failed to extract tmux source, skipping" >&2
        rm -rf "$tmpdir"
        return 0
    }

    # Configure and build
    if ./configure --prefix=/usr/local && make -j"$(nproc)" && make install; then
        echo "tmux installed successfully"
    else
        echo "WARNING: Failed to build tmux" >&2
    fi

    cd - >/dev/null || true
    rm -rf "$tmpdir"
    return 0
}

# Install lazygit from GitHub Releases
install_lazygit() {
    if [ "$INSTALL_LAZYGIT" != "true" ]; then
        echo "Skipping lazygit installation (disabled)"
        return 0
    fi

    echo "Installing lazygit..."
    local version="$LAZYGIT_VERSION"

    if [ "$version" = "latest" ]; then
        version=$(get_latest_version "jesseduffield/lazygit")
    fi

    if [ -z "$version" ]; then
        echo "WARNING: Could not determine lazygit version, skipping" >&2
        return 0
    fi

    # Strip leading 'v' if present for URL construction
    local version_num="${version#v}"
    echo "lazygit version: $version_num"

    local lazygit_arch="$ARCH"
    if [ "$ARCH" = "amd64" ]; then
        lazygit_arch="x86_64"
    elif [ "$ARCH" = "arm64" ]; then
        lazygit_arch="arm64"
    fi

    local url="https://github.com/jesseduffield/lazygit/releases/download/v${version_num}/lazygit_${version_num}_Linux_${lazygit_arch}.tar.gz"
    local tmpdir
    tmpdir=$(mktemp -d)

    if download_file "$url" "$tmpdir/lazygit.tar.gz"; then
        tar -xzf "$tmpdir/lazygit.tar.gz" -C "$tmpdir"
        install -m 755 "$tmpdir/lazygit" "$INSTALL_DIR/lazygit"
        echo "lazygit installed successfully"
    else
        echo "WARNING: Failed to install lazygit" >&2
    fi

    rm -rf "$tmpdir"
    return 0
}

# Install neovim from GitHub Releases
install_nvim() {
    if [ "$INSTALL_NVIM" != "true" ]; then
        echo "Skipping neovim installation (disabled)"
        return 0
    fi

    echo "Installing neovim..."
    local version="$NVIM_VERSION"

    if [ "$version" = "latest" ]; then
        version=$(get_latest_version "neovim/neovim")
    fi

    if [ -z "$version" ]; then
        echo "WARNING: Could not determine neovim version, skipping" >&2
        return 0
    fi

    echo "neovim version: $version"

    local nvim_arch
    if [ "$ARCH" = "amd64" ]; then
        nvim_arch="x86_64"
    elif [ "$ARCH" = "arm64" ]; then
        nvim_arch="arm64"
    else
        echo "WARNING: Unsupported architecture for neovim: $ARCH" >&2
        return 0
    fi

    local url="https://github.com/neovim/neovim/releases/download/${version}/nvim-linux-${nvim_arch}.tar.gz"
    local tmpdir
    tmpdir=$(mktemp -d)

    if download_file "$url" "$tmpdir/nvim.tar.gz"; then
        tar -xzf "$tmpdir/nvim.tar.gz" -C "$tmpdir"
        # neovim extracts to nvim-linux-<arch> directory
        cp -r "$tmpdir"/nvim-linux-"${nvim_arch}"/* /usr/local/
        echo "neovim installed successfully"
    else
        echo "WARNING: Failed to install neovim" >&2
    fi

    rm -rf "$tmpdir"

    # Install supporting tools for neovim
    install_ripgrep
    install_fd
    install_fzf

    # Set environment variables for neovim
    echo "export EDITOR=nvim" >> /etc/profile.d/devenv.sh
    echo "export VISUAL=nvim" >> /etc/profile.d/devenv.sh

    return 0
}

# Install ripgrep from GitHub Releases
install_ripgrep() {
    echo "Installing ripgrep..."
    local version
    version=$(get_latest_version "BurntSushi/ripgrep")

    if [ -z "$version" ]; then
        echo "WARNING: Could not determine ripgrep version, skipping" >&2
        return 0
    fi

    local version_num="${version#v}"
    echo "ripgrep version: $version_num"

    local rg_arch
    if [ "$ARCH" = "amd64" ]; then
        rg_arch="x86_64-unknown-linux-musl"
    elif [ "$ARCH" = "arm64" ]; then
        rg_arch="aarch64-unknown-linux-gnu"
    else
        echo "WARNING: Unsupported architecture for ripgrep: $ARCH" >&2
        return 0
    fi

    local url="https://github.com/BurntSushi/ripgrep/releases/download/${version_num}/ripgrep-${version_num}-${rg_arch}.tar.gz"
    local tmpdir
    tmpdir=$(mktemp -d)

    if download_file "$url" "$tmpdir/ripgrep.tar.gz"; then
        tar -xzf "$tmpdir/ripgrep.tar.gz" -C "$tmpdir"
        install -m 755 "$tmpdir/ripgrep-${version_num}-${rg_arch}/rg" "$INSTALL_DIR/rg"
        echo "ripgrep installed successfully"
    else
        echo "WARNING: Failed to install ripgrep" >&2
    fi

    rm -rf "$tmpdir"
    return 0
}

# Install fd from GitHub Releases
install_fd() {
    echo "Installing fd..."
    local version
    version=$(get_latest_version "sharkdp/fd")

    if [ -z "$version" ]; then
        echo "WARNING: Could not determine fd version, skipping" >&2
        return 0
    fi

    local version_num="${version#v}"
    echo "fd version: $version_num"

    local fd_arch
    if [ "$ARCH" = "amd64" ]; then
        fd_arch="x86_64-unknown-linux-musl"
    elif [ "$ARCH" = "arm64" ]; then
        fd_arch="aarch64-unknown-linux-gnu"
    else
        echo "WARNING: Unsupported architecture for fd: $ARCH" >&2
        return 0
    fi

    local url="https://github.com/sharkdp/fd/releases/download/v${version_num}/fd-v${version_num}-${fd_arch}.tar.gz"
    local tmpdir
    tmpdir=$(mktemp -d)

    if download_file "$url" "$tmpdir/fd.tar.gz"; then
        tar -xzf "$tmpdir/fd.tar.gz" -C "$tmpdir"
        install -m 755 "$tmpdir/fd-v${version_num}-${fd_arch}/fd" "$INSTALL_DIR/fd"
        echo "fd installed successfully"
    else
        echo "WARNING: Failed to install fd" >&2
    fi

    rm -rf "$tmpdir"
    return 0
}

# Install fzf from GitHub Releases
install_fzf() {
    echo "Installing fzf..."
    local version
    version=$(get_latest_version "junegunn/fzf")

    if [ -z "$version" ]; then
        echo "WARNING: Could not determine fzf version, skipping" >&2
        return 0
    fi

    local version_num="${version#v}"
    echo "fzf version: $version_num"

    local fzf_arch
    if [ "$ARCH" = "amd64" ]; then
        fzf_arch="linux_amd64"
    elif [ "$ARCH" = "arm64" ]; then
        fzf_arch="linux_arm64"
    else
        echo "WARNING: Unsupported architecture for fzf: $ARCH" >&2
        return 0
    fi

    local url="https://github.com/junegunn/fzf/releases/download/v${version_num}/fzf-${version_num}-${fzf_arch}.tar.gz"
    local tmpdir
    tmpdir=$(mktemp -d)

    if download_file "$url" "$tmpdir/fzf.tar.gz"; then
        tar -xzf "$tmpdir/fzf.tar.gz" -C "$tmpdir"
        install -m 755 "$tmpdir/fzf" "$INSTALL_DIR/fzf"
        echo "fzf installed successfully"
    else
        echo "WARNING: Failed to install fzf" >&2
    fi

    rm -rf "$tmpdir"
    return 0
}

# Install Claude Code CLI
install_claude_code() {
    if [ "$INSTALL_CLAUDE_CODE" != "true" ]; then
        echo "Skipping Claude Code installation (disabled)"
        return 0
    fi

    echo "Installing Claude Code..."

    # Check if claude is already installed (check as remote user since it installs to user home)
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "command -v claude" &>/dev/null; then
            echo "Claude Code is already installed, skipping"
            return 0
        fi
    elif command -v claude &>/dev/null; then
        echo "Claude Code is already installed, skipping"
        return 0
    fi

    # Install as the remote user so binaries go to their home directory
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "curl -fsSL https://claude.ai/install.sh | bash"; then
            echo "Claude Code installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install Claude Code" >&2
        fi
    else
        if curl -fsSL https://claude.ai/install.sh | bash; then
            echo "Claude Code installed successfully"
        else
            echo "WARNING: Failed to install Claude Code" >&2
        fi
    fi

    return 0
}

# Install OpenAI Codex CLI
install_codex() {
    if [ "$INSTALL_CODEX" != "true" ]; then
        echo "Skipping Codex installation (disabled)"
        return 0
    fi

    echo "Installing Codex..."

    # Check if codex is already installed (check as remote user first)
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "command -v codex" &>/dev/null; then
            echo "Codex is already installed, skipping"
            return 0
        fi
    elif command -v codex &>/dev/null; then
        echo "Codex is already installed, skipping"
        return 0
    fi

    # Try installing as remote user if they have npm available
    if [ "$REMOTE_USER" != "root" ] && su - "$REMOTE_USER" -c "command -v npm" &>/dev/null; then
        if su - "$REMOTE_USER" -c "npm i -g @openai/codex"; then
            echo "Codex installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install Codex" >&2
        fi
    elif command -v npm &>/dev/null; then
        # Fallback: install as root (system-wide)
        if npm i -g @openai/codex; then
            echo "Codex installed successfully"
        else
            echo "WARNING: Failed to install Codex" >&2
        fi
    else
        echo "WARNING: npm is not installed, skipping Codex installation" >&2
    fi

    return 0
}

# Install GitHub CLI from GitHub Releases
install_gh() {
    if [ "$INSTALL_GH" != "true" ]; then
        echo "Skipping GitHub CLI installation (disabled)"
        return 0
    fi

    echo "Installing GitHub CLI..."

    # Check if gh is already installed
    if command -v gh &>/dev/null; then
        echo "GitHub CLI is already installed, skipping"
        return 0
    fi

    local version
    version=$(get_latest_version "cli/cli")

    if [ -z "$version" ]; then
        echo "WARNING: Could not determine GitHub CLI version, skipping" >&2
        return 0
    fi

    local version_num="${version#v}"
    echo "GitHub CLI version: $version_num"

    local gh_arch
    if [ "$ARCH" = "amd64" ]; then
        gh_arch="linux_amd64"
    elif [ "$ARCH" = "arm64" ]; then
        gh_arch="linux_arm64"
    else
        echo "WARNING: Unsupported architecture for GitHub CLI: $ARCH" >&2
        return 0
    fi

    local url="https://github.com/cli/cli/releases/download/v${version_num}/gh_${version_num}_${gh_arch}.tar.gz"
    local tmpdir
    tmpdir=$(mktemp -d)

    if download_file "$url" "$tmpdir/gh.tar.gz"; then
        tar -xzf "$tmpdir/gh.tar.gz" -C "$tmpdir"
        install -m 755 "$tmpdir/gh_${version_num}_${gh_arch}/bin/gh" "$INSTALL_DIR/gh"
        echo "GitHub CLI installed successfully"
    else
        echo "WARNING: Failed to install GitHub CLI" >&2
    fi

    rm -rf "$tmpdir"
    return 0
}

# Install opencode
install_opencode() {
    if [ "$INSTALL_OPENCODE" != "true" ]; then
        echo "Skipping opencode installation (disabled)"
        return 0
    fi

    echo "Installing opencode..."

    # Check if opencode is already installed (check as remote user first)
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "command -v opencode" &>/dev/null; then
            echo "opencode is already installed, skipping"
            return 0
        fi
    elif command -v opencode &>/dev/null; then
        echo "opencode is already installed, skipping"
        return 0
    fi

    # Install as the remote user so binaries go to their home directory
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "curl -fsSL https://opencode.ai/install | bash"; then
            echo "opencode installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install opencode" >&2
        fi
    else
        if curl -fsSL https://opencode.ai/install | bash; then
            echo "opencode installed successfully"
        else
            echo "WARNING: Failed to install opencode" >&2
        fi
    fi

    return 0
}


# Install fdsx via uv tool
install_fdsx() {
    if [ "$INSTALL_FDSX" != "true" ]; then
        echo "Skipping fdsx installation (disabled)"
        return 0
    fi

    echo "Installing fdsx..."

    # Check if fdsx is already installed (check as remote user first)
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "command -v fdsx" &>/dev/null; then
            echo "fdsx is already installed, skipping"
            return 0
        fi
    elif command -v fdsx &>/dev/null; then
        echo "fdsx is already installed, skipping"
        return 0
    fi

    # Helper: run a command as user, sourcing uv env if available
    run_with_uv() {
        local run_as="$1"
        shift
        local cmd="$*"
        # Source uv env to ensure uv and uv-installed tools are in PATH
        local uv_env="export PATH=\"\$HOME/.local/bin:\$HOME/.cargo/bin:\$PATH\""
        if [ -n "$run_as" ]; then
            su - "$run_as" -c "$uv_env && $cmd"
        else
            eval "$uv_env && $cmd"
        fi
    }

    # Install uv if not available, then install fdsx
    if [ "$REMOTE_USER" != "root" ]; then
        if ! su - "$REMOTE_USER" -c "command -v uv" &>/dev/null; then
            echo "Installing uv for user $REMOTE_USER..."
            su - "$REMOTE_USER" -c "curl -LsSf https://astral.sh/uv/install.sh | sh" || {
                echo "WARNING: Failed to install uv, skipping fdsx installation" >&2
                return 0
            }
        fi
        if run_with_uv "$REMOTE_USER" "uv tool install fdsx"; then
            echo "fdsx installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install fdsx" >&2
        fi
    else
        if ! command -v uv &>/dev/null; then
            echo "Installing uv..."
            curl -LsSf https://astral.sh/uv/install.sh | sh || {
                echo "WARNING: Failed to install uv, skipping fdsx installation" >&2
                return 0
            }
        fi
        if run_with_uv "" "uv tool install fdsx"; then
            echo "fdsx installed successfully"
        else
            echo "WARNING: Failed to install fdsx" >&2
        fi
    fi

    return 0
}

# Ensure Node.js is available for pi installer in non-interactive containers
ensure_node_for_pi() {
    if command -v node &>/dev/null && command -v npm &>/dev/null && node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || (major === 22 && minor >= 19) ? 0 : 1)' &>/dev/null; then
        return 0
    fi

    echo "Installing Node.js for pi..."
    local version="22.19.0"
    local node_arch
    if [ "$ARCH" = "amd64" ]; then
        node_arch="x64"
    elif [ "$ARCH" = "arm64" ]; then
        node_arch="arm64"
    else
        echo "WARNING: Unsupported architecture for Node.js: $ARCH" >&2
        return 1
    fi

    local url="https://nodejs.org/dist/v${version}/node-v${version}-linux-${node_arch}.tar.xz"
    local tmpdir
    tmpdir=$(mktemp -d)

    if download_file "$url" "$tmpdir/node.tar.xz"; then
        tar -xJf "$tmpdir/node.tar.xz" -C "$tmpdir"
        cp -r "$tmpdir/node-v${version}-linux-${node_arch}"/* /usr/local/
        echo "Node.js installed successfully for pi"
    else
        echo "WARNING: Failed to install Node.js for pi" >&2
        rm -rf "$tmpdir"
        return 1
    fi

    rm -rf "$tmpdir"
    return 0
}

# Install pi coding agent
install_pi() {
    if [ "$INSTALL_PI" != "true" ]; then
        echo "Skipping pi installation (disabled)"
        return 0
    fi

    echo "Installing pi..."

    # Check if pi is already installed (check as remote user first)
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "command -v pi" &>/dev/null; then
            echo "pi is already installed, skipping"
            return 0
        fi
    elif command -v pi &>/dev/null; then
        echo "pi is already installed, skipping"
        return 0
    fi

    if ! ensure_node_for_pi; then
        echo "WARNING: Node.js is required for pi installation, skipping pi" >&2
        return 0
    fi

    # Install as the remote user so binaries go to their home directory
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "curl -fsSL https://pi.dev/install.sh | sh"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> /etc/profile.d/devenv.sh
            echo "pi installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install pi" >&2
        fi
    else
        if curl -fsSL https://pi.dev/install.sh | sh; then
            echo "pi installed successfully"
        else
            echo "WARNING: Failed to install pi" >&2
        fi
    fi

    return 0
}

# Install rtk (Rust Token Killer)
install_rtk() {
    if [ "$INSTALL_RTK" != "true" ]; then
        echo "Skipping rtk installation (disabled)"
        return 0
    fi

    echo "Installing rtk..."

    # Check if rtk is already installed (check as remote user first)
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "command -v rtk" &>/dev/null; then
            echo "rtk is already installed, skipping"
            return 0
        fi
    elif command -v rtk &>/dev/null; then
        echo "rtk is already installed, skipping"
        return 0
    fi

    # Install as the remote user so binaries go to their home directory
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"; then
            echo "rtk installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install rtk" >&2
        fi
    else
        if curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh; then
            echo "rtk installed successfully"
        else
            echo "WARNING: Failed to install rtk" >&2
        fi
    fi

    return 0
}

# Main installation
main() {
    echo "Starting devenv feature installation..."
    echo "Remote user: $REMOTE_USER (home: $REMOTE_USER_HOME)"
    echo "Options:"
    echo "  INSTALL_TMUX=$INSTALL_TMUX"
    echo "  INSTALL_LAZYGIT=$INSTALL_LAZYGIT"
    echo "  INSTALL_NVIM=$INSTALL_NVIM"
    echo "  INSTALL_CLAUDE_CODE=$INSTALL_CLAUDE_CODE"
    echo "  INSTALL_CODEX=$INSTALL_CODEX"
    echo "  INSTALL_GH=$INSTALL_GH"
    echo "  INSTALL_OPENCODE=$INSTALL_OPENCODE"
    echo "  INSTALL_FDSX=$INSTALL_FDSX"
    echo "  INSTALL_RTK=$INSTALL_RTK"
    echo "  INSTALL_PI=$INSTALL_PI"
    echo "  TMUX_VERSION=$TMUX_VERSION"
    echo "  LAZYGIT_VERSION=$LAZYGIT_VERSION"
    echo "  NVIM_VERSION=$NVIM_VERSION"

    if [ "$ARCH" = "unknown" ]; then
        echo "WARNING: Unknown architecture, some tools may not install correctly" >&2
    fi

    # Create profile.d directory if it doesn't exist
    mkdir -p /etc/profile.d

    install_dependencies
    install_tmux
    install_lazygit
    install_nvim
    install_claude_code
    install_codex
    install_gh
    install_opencode
    install_fdsx
    install_rtk
    install_pi

    echo "devenv feature installation complete"
}

main "$@"
