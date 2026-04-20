#!/bin/bash
set -e

# devenv feature install script
# Installs tmux, lazygit, neovim (with supporting tools: ripgrep, fd, fzf), and gh
# All tools installed from GitHub Releases

# Options (passed as environment variables)
INSTALL_TMUX="${INSTALLTMUX:-true}"
INSTALL_LAZYGIT="${INSTALLLAZYGIT:-true}"
INSTALL_NVIM="${INSTALLNVIM:-true}"
INSTALL_CLAUDE_CODE="${INSTALLCLAUDECODE:-true}"
INSTALL_CODEX="${INSTALLCODEX:-true}"
INSTALL_GH="${INSTALLGH:-true}"
INSTALL_TAKT="${INSTALLTAKT:-true}"
INSTALL_OPENCODE="${INSTALLOPENCODE:-true}"
INSTALL_GEMINI="${INSTALLGEMINI:-true}"
INSTALL_FDSX="${INSTALLFDSX:-true}"
INSTALL_RTK="${INSTALLRTK:-true}"
INSTALL_OP="${INSTALLOP:-true}"
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

# Install takt
install_takt() {
    if [ "$INSTALL_TAKT" != "true" ]; then
        echo "Skipping takt installation (disabled)"
        return 0
    fi

    echo "Installing takt..."

    # Check if takt is already installed (check as remote user first)
    if [ "$REMOTE_USER" != "root" ] && su - "$REMOTE_USER" -c "command -v takt" &>/dev/null; then
        echo "takt is already installed, skipping"
        return 0
    elif command -v takt &>/dev/null; then
        echo "takt is already installed, skipping"
        return 0
    fi

    # Try installing as remote user if they have npm available
    if [ "$REMOTE_USER" != "root" ] && su - "$REMOTE_USER" -c "command -v npm" &>/dev/null; then
        if su - "$REMOTE_USER" -c "npm install -g takt"; then
            echo "takt installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install takt" >&2
        fi
    elif command -v npm &>/dev/null; then
        # Fallback: install as root (system-wide)
        if npm install -g takt; then
            echo "takt installed successfully"
        else
            echo "WARNING: Failed to install takt" >&2
        fi
    else
        echo "WARNING: npm is not installed, skipping takt installation" >&2
    fi

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

# Install Gemini CLI
install_gemini() {
    if [ "$INSTALL_GEMINI" != "true" ]; then
        echo "Skipping Gemini CLI installation (disabled)"
        return 0
    fi

    echo "Installing Gemini CLI..."

    # Check if gemini is already installed (check as remote user first)
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "command -v gemini" &>/dev/null; then
            echo "Gemini CLI is already installed, skipping"
            return 0
        fi
    elif command -v gemini &>/dev/null; then
        echo "Gemini CLI is already installed, skipping"
        return 0
    fi

    # Try installing as remote user if they have npm available
    if [ "$REMOTE_USER" != "root" ] && su - "$REMOTE_USER" -c "command -v npm" &>/dev/null; then
        if su - "$REMOTE_USER" -c "npm install -g @google/gemini-cli"; then
            echo "Gemini CLI installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install Gemini CLI" >&2
        fi
    elif command -v npm &>/dev/null; then
        # Fallback: install as root (system-wide)
        if npm install -g @google/gemini-cli; then
            echo "Gemini CLI installed successfully"
        else
            echo "WARNING: Failed to install Gemini CLI" >&2
        fi
    else
        echo "WARNING: npm is not installed, skipping Gemini CLI installation" >&2
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

# Install 1Password CLI (op) from cache.agilebits.com
install_op() {
    if [ "$INSTALL_OP" != "true" ]; then
        echo "Skipping 1Password CLI installation (disabled)"
        return 0
    fi

    echo "Installing 1Password CLI (op)..."

    if command -v op &>/dev/null; then
        echo "1Password CLI is already installed, skipping"
        return 0
    fi

    # Ensure unzip is available
    if ! command -v unzip &>/dev/null; then
        if command -v apt-get &>/dev/null; then
            apt-get install -y --no-install-recommends unzip
        elif command -v apk &>/dev/null; then
            apk add --no-cache unzip
        elif command -v dnf &>/dev/null; then
            dnf install -y unzip
        else
            echo "WARNING: Cannot install unzip, skipping 1Password CLI" >&2
            return 0
        fi
    fi

    local op_arch
    if [ "$ARCH" = "amd64" ]; then
        op_arch="amd64"
    elif [ "$ARCH" = "arm64" ]; then
        op_arch="arm64"
    else
        echo "WARNING: Unsupported architecture for 1Password CLI: $ARCH" >&2
        return 0
    fi

    # Resolve latest version from 1Password product history
    local version
    version=$(curl -sL https://app-updates.agilebits.com/product_history/CLI2 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)

    if [ -z "$version" ]; then
        echo "WARNING: Could not determine 1Password CLI version, skipping" >&2
        return 0
    fi

    echo "1Password CLI version: $version"

    local url="https://cache.agilebits.com/dist/1P/op2/pkg/${version}/op_linux_${op_arch}_${version}.zip"
    local tmpdir
    tmpdir=$(mktemp -d)

    if download_file "$url" "$tmpdir/op.zip"; then
        unzip -o "$tmpdir/op.zip" -d "$tmpdir" >/dev/null
        install -m 755 "$tmpdir/op" "$INSTALL_DIR/op"
        echo "1Password CLI installed successfully"
    else
        echo "WARNING: Failed to install 1Password CLI" >&2
    fi

    rm -rf "$tmpdir"
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
    echo "  INSTALL_TAKT=$INSTALL_TAKT"
    echo "  INSTALL_OPENCODE=$INSTALL_OPENCODE"
    echo "  INSTALL_GEMINI=$INSTALL_GEMINI"
    echo "  INSTALL_FDSX=$INSTALL_FDSX"
    echo "  INSTALL_RTK=$INSTALL_RTK"
    echo "  INSTALL_OP=$INSTALL_OP"
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
    install_takt
    install_opencode
    install_gemini
    install_fdsx
    install_rtk
    install_op

    echo "devenv feature installation complete"
}

main "$@"
