#!/bin/bash
set -e

# tools feature install script
# Installs lazygit, neovim (with supporting tools: ripgrep, fd, fzf), gh,
# Claude Code, Codex, fdsx, rtk, pi, build tools, optional Tailscale access, and OpenSSH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Options (passed as environment variables)
INSTALL_LAZYGIT="${INSTALLLAZYGIT:-true}"
INSTALL_NVIM="${INSTALLNVIM:-true}"
INSTALL_CLAUDE_CODE="${INSTALLCLAUDECODE:-true}"
INSTALL_CODEX="${INSTALLCODEX:-true}"
INSTALL_GH="${INSTALLGH:-true}"
INSTALL_FDSX="${INSTALLFDSX:-true}"
INSTALL_RTK="${INSTALLRTK:-true}"
INSTALL_PI="${INSTALLPI:-true}"
INSTALL_TAILSCALE="${INSTALLTAILSCALE:-true}"
INSTALL_SSHD="${INSTALLSSHD:-true}"
INSTALL_BUILD_TOOLS="${INSTALLBUILDTOOLS:-true}"
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
    local response=""
    local latest_url=""
    local version=""

    # Prefer the GitHub API when available. Match the exact top-level tag_name key
    # instead of any quoted string on the line.
    response=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null || true)
    if [ -n "$response" ]; then
        version=$(printf '%s\n' "$response" | awk -F'"' '/^[[:space:]]*"tag_name"[[:space:]]*:/ { print $4; exit }')
    fi

    # Fallback to the releases/latest redirect target. This avoids failing on
    # transient API response shape/rate-limit issues and still yields the tag.
    if [ -z "$version" ]; then
        latest_url=$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${repo}/releases/latest" 2>/dev/null || true)
        case "$latest_url" in
            */tag/*)
                version="${latest_url##*/tag/}"
                version="${version%%[?#]*}"
                ;;
        esac
    fi

    if [ -z "$version" ]; then
        echo "WARNING: Could not determine latest release version for ${repo}" >&2
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

link_user_bin() {
    local command_name="$1"
    local user_home="${2:-$REMOTE_USER_HOME}"
    local source_path="${user_home}/.local/bin/${command_name}"

    if command -v "$command_name" &>/dev/null; then
        return 0
    fi

    if [ -x "$source_path" ]; then
        ln -sf "$source_path" "$INSTALL_DIR/$command_name"
    fi
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

has_build_tools() {
    command -v python3 &>/dev/null \
        && command -v make &>/dev/null \
        && { command -v g++ &>/dev/null || command -v clang++ &>/dev/null; }
}

install_build_tools() {
    if [ "$INSTALL_BUILD_TOOLS" != "true" ]; then
        echo "Skipping C/C++ build tools installation (disabled)"
        return 0
    fi

    if has_build_tools; then
        echo "C/C++ build tools are already installed, skipping"
        return 0
    fi

    echo "Installing C/C++ build tools..."
    if command -v apt-get &>/dev/null; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends build-essential python3
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk &>/dev/null; then
        apk add --no-cache build-base python3
    elif command -v dnf &>/dev/null; then
        dnf install -y make gcc-c++ python3
    else
        echo "WARNING: Could not find a supported package manager for C/C++ build tools" >&2
        return 0
    fi
}

is_debian_or_ubuntu() {
    if [ ! -r /etc/os-release ]; then
        return 1
    fi

    # shellcheck source=/dev/null
    . /etc/os-release

    case "${ID:-}:${ID_LIKE:-}" in
        debian:*|ubuntu:*|*:debian*|*:ubuntu*)
            return 0
            ;;
    esac

    return 1
}

install_tailscale() {
    if [ "$INSTALL_TAILSCALE" != "true" ]; then
        if [ -f "${SCRIPT_DIR}/tailscale-entrypoint.sh" ]; then
            install -m 755 "${SCRIPT_DIR}/tailscale-entrypoint.sh" /usr/local/bin/tailscale-entrypoint.sh
        fi
        echo "Skipping Tailscale installation (disabled)"
        return 0
    fi

    if [ ! -f "${SCRIPT_DIR}/tailscale-entrypoint.sh" ]; then
        echo "ERROR: tailscale-entrypoint.sh must be in the same directory as install.sh when installTailscale is enabled." >&2
        return 1
    fi

    install -m 755 "${SCRIPT_DIR}/tailscale-entrypoint.sh" /usr/local/bin/tailscale-entrypoint.sh

    if ! is_debian_or_ubuntu; then
        echo "ERROR: installTailscale requires a Debian/Ubuntu based image. Set installTailscale=false to skip it." >&2
        return 1
    fi

    echo "Installing Tailscale..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        iproute2 \
        iptables \
        procps

    curl -fsSL https://tailscale.com/install.sh | sh

    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

install_sshd() {
    if [ "$INSTALL_SSHD" != "true" ]; then
        echo "Skipping OpenSSH server installation (disabled)"
        return 0
    fi

    echo "Installing OpenSSH server..."
    if command -v apt-get &>/dev/null; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends openssh-server
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk &>/dev/null; then
        apk add --no-cache openssh-server
    elif command -v dnf &>/dev/null; then
        dnf install -y openssh-server
    else
        echo "WARNING: Could not find a supported package manager for OpenSSH server" >&2
        return 0
    fi

    mkdir -p /run/sshd /var/lib/ssh-host-keys
    chmod 755 /run/sshd

    if [ -f /etc/ssh/sshd_config ]; then
        sed -i \
            -e 's/^[#[:space:]]*PermitRootLogin.*/PermitRootLogin prohibit-password/' \
            -e 's/^[#[:space:]]*PasswordAuthentication.*/PasswordAuthentication no/' \
            -e 's/^[#[:space:]]*PubkeyAuthentication.*/PubkeyAuthentication yes/' \
            -e 's/^[#[:space:]]*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' \
            /etc/ssh/sshd_config
    fi

    # Runtime entrypoint creates stable per-volume host keys instead of baking
    # build-time keys into the image.
    rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
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
    echo "export EDITOR=nvim" >> /etc/profile.d/tools.sh
    echo "export VISUAL=nvim" >> /etc/profile.d/tools.sh

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
            link_user_bin "claude" "$REMOTE_USER_HOME"
            echo "Claude Code installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install Claude Code" >&2
        fi
    else
        if curl -fsSL https://claude.ai/install.sh | bash; then
            link_user_bin "claude" "$REMOTE_USER_HOME"
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

    if ! command -v npm &>/dev/null && ! ensure_node; then
        echo "WARNING: npm is not installed, skipping Codex installation" >&2
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
            link_user_bin "fdsx" "$REMOTE_USER_HOME"
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
            link_user_bin "fdsx" "$REMOTE_USER_HOME"
            echo "fdsx installed successfully"
        else
            echo "WARNING: Failed to install fdsx" >&2
        fi
    fi

    return 0
}

# Ensure Node.js is available for npm-backed installers in non-interactive containers
ensure_node() {
    if command -v node &>/dev/null && command -v npm &>/dev/null && node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || (major === 22 && minor >= 19) ? 0 : 1)' &>/dev/null; then
        return 0
    fi

    echo "Installing Node.js..."
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
        echo "Node.js installed successfully"
    else
        echo "WARNING: Failed to install Node.js" >&2
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

    if ! ensure_node; then
        echo "WARNING: Node.js is required for pi installation, skipping pi" >&2
        return 0
    fi

    # Install as the remote user so binaries go to their home directory
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "curl -fsSL https://pi.dev/install.sh | sh"; then
            # shellcheck disable=SC2016
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> /etc/profile.d/tools.sh
            link_user_bin "pi" "$REMOTE_USER_HOME"
            echo "pi installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install pi" >&2
        fi
    else
        if curl -fsSL https://pi.dev/install.sh | sh; then
            link_user_bin "pi" "$REMOTE_USER_HOME"
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
            link_user_bin "rtk" "$REMOTE_USER_HOME"
            echo "rtk installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install rtk" >&2
        fi
    else
        if curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh; then
            link_user_bin "rtk" "$REMOTE_USER_HOME"
            echo "rtk installed successfully"
        else
            echo "WARNING: Failed to install rtk" >&2
        fi
    fi

    return 0
}

# Main installation
main() {
    echo "Starting tools feature installation..."
    echo "Remote user: $REMOTE_USER (home: $REMOTE_USER_HOME)"
    echo "Options:"
    echo "  INSTALL_LAZYGIT=$INSTALL_LAZYGIT"
    echo "  INSTALL_NVIM=$INSTALL_NVIM"
    echo "  INSTALL_CLAUDE_CODE=$INSTALL_CLAUDE_CODE"
    echo "  INSTALL_CODEX=$INSTALL_CODEX"
    echo "  INSTALL_GH=$INSTALL_GH"
    echo "  INSTALL_FDSX=$INSTALL_FDSX"
    echo "  INSTALL_RTK=$INSTALL_RTK"
    echo "  INSTALL_PI=$INSTALL_PI"
    echo "  INSTALL_TAILSCALE=$INSTALL_TAILSCALE"
    echo "  INSTALL_SSHD=$INSTALL_SSHD"
    echo "  INSTALL_BUILD_TOOLS=$INSTALL_BUILD_TOOLS"
    echo "  LAZYGIT_VERSION=$LAZYGIT_VERSION"
    echo "  NVIM_VERSION=$NVIM_VERSION"

    if [ "$ARCH" = "unknown" ]; then
        echo "WARNING: Unknown architecture, some tools may not install correctly" >&2
    fi

    # Create profile.d directory if it doesn't exist
    mkdir -p /etc/profile.d

    install_dependencies
    install_build_tools
    install_tailscale
    install_sshd
    install_lazygit
    install_nvim
    install_claude_code
    install_codex
    install_gh
    install_fdsx
    install_rtk
    install_pi

    echo "tools feature installation complete"
}

main "$@"
