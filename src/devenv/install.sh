#!/bin/bash
set -e

# devenv feature install script
# Installs tmux, lazygit, neovim (with supporting tools: ripgrep, fd, fzf)
# All tools installed from GitHub Releases

# Options (passed as environment variables)
INSTALL_TMUX="${INSTALLTMUX:-true}"
INSTALL_LAZYGIT="${INSTALLLAZYGIT:-true}"
INSTALL_NVIM="${INSTALLNVIM:-true}"
INSTALL_CLAUDE_CODE="${INSTALLCLAUDECODE:-true}"
INSTALL_CODEX="${INSTALLCODEX:-true}"
TMUX_VERSION="${TMUXVERSION:-latest}"
LAZYGIT_VERSION="${LAZYGITVERSION:-latest}"
NVIM_VERSION="${NVIMVERSION:-latest}"

# Installation target
INSTALL_DIR="/usr/local/bin"

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
    local version
    version=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
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
        apt-get install -y --no-install-recommends curl ca-certificates tar gzip
    elif command -v apk &>/dev/null; then
        apk add --no-cache curl ca-certificates tar gzip
    elif command -v dnf &>/dev/null; then
        dnf install -y curl ca-certificates tar gzip
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

    # Check if claude is already installed
    if command -v claude &>/dev/null; then
        echo "Claude Code is already installed, skipping"
        return 0
    fi

    # Install Claude Code using the official install script
    if curl -fsSL https://claude.ai/install.sh | bash; then
        echo "Claude Code installed successfully"
    else
        echo "WARNING: Failed to install Claude Code" >&2
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

    # Check if codex is already installed
    if command -v codex &>/dev/null; then
        echo "Codex is already installed, skipping"
        return 0
    fi

    # Check if npm is available
    if ! command -v npm &>/dev/null; then
        echo "WARNING: npm is not installed, skipping Codex installation" >&2
        return 0
    fi

    # Install Codex globally using npm
    if npm i -g @openai/codex; then
        echo "Codex installed successfully"
    else
        echo "WARNING: Failed to install Codex" >&2
    fi

    return 0
}

# Main installation
main() {
    echo "Starting devenv feature installation..."
    echo "Options:"
    echo "  INSTALL_TMUX=$INSTALL_TMUX"
    echo "  INSTALL_LAZYGIT=$INSTALL_LAZYGIT"
    echo "  INSTALL_NVIM=$INSTALL_NVIM"
    echo "  INSTALL_CLAUDE_CODE=$INSTALL_CLAUDE_CODE"
    echo "  INSTALL_CODEX=$INSTALL_CODEX"
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

    echo "devenv feature installation complete"
}

main "$@"
