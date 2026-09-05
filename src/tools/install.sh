#!/bin/bash
set -e

# tools feature install script
# Installs lazygit, neovim (with supporting tools: ripgrep, fd, fzf), gh, op,
# Claude Code, Codex, opencode, Grok, Cursor Agent, fdsx, rtk, witr, pi, and Oh My Pi

# Options (passed as environment variables)
INSTALL_LAZYGIT="${INSTALLLAZYGIT:-true}"
INSTALL_NVIM="${INSTALLNVIM:-true}"
INSTALL_CLAUDE_CODE="${INSTALLCLAUDECODE:-true}"
INSTALL_CODEX="${INSTALLCODEX:-false}"
INSTALL_OPENCODE="${INSTALLOPENCODE:-true}"
INSTALL_GROK="${INSTALLGROK:-true}"
INSTALL_CURSOR="${INSTALLCURSOR:-true}"
INSTALL_GH="${INSTALLGH:-true}"
INSTALL_OP="${INSTALLOP:-true}"
INSTALL_FDSX="${INSTALLFDSX:-true}"
INSTALL_RTK="${INSTALLRTK:-true}"
INSTALL_WITR="${INSTALLWITR:-true}"
INSTALL_PI="${INSTALLPI:-true}"
INSTALL_OH_MY_PI="${INSTALLOHMYPI:-true}"
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

    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh"; then
            link_user_bin "codex" "$REMOTE_USER_HOME"
            echo "Codex installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install Codex" >&2
        fi
    else
        if curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh; then
            link_user_bin "codex" "$REMOTE_USER_HOME"
            echo "Codex installed successfully"
        else
            echo "WARNING: Failed to install Codex" >&2
        fi
    fi

    return 0
}

# Install opencode
link_opencode_bin() {
    local user_home="${1:-$REMOTE_USER_HOME}"
    if [ -x "${user_home}/.opencode/bin/opencode" ]; then
        ln -sf "${user_home}/.opencode/bin/opencode" "$INSTALL_DIR/opencode"
    else
        link_user_bin "opencode" "$user_home"
    fi
}

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
            link_opencode_bin "$REMOTE_USER_HOME"
            return 0
        fi
    elif command -v opencode &>/dev/null; then
        echo "opencode is already installed, skipping"
        link_opencode_bin "$REMOTE_USER_HOME"
        return 0
    fi

    # Install as the remote user so binaries go to their home directory
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "curl -fsSL https://opencode.ai/install | bash"; then
            link_opencode_bin "$REMOTE_USER_HOME"
            echo "opencode installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install opencode" >&2
        fi
    else
        if curl -fsSL https://opencode.ai/install | bash; then
            link_opencode_bin "$REMOTE_USER_HOME"
            echo "opencode installed successfully"
        else
            echo "WARNING: Failed to install opencode" >&2
        fi
    fi

    return 0
}

# Install Grok CLI
remove_grok_agent_aliases() {
    local grok_agent="$REMOTE_USER_HOME/.grok/bin/agent"
    local grok_agent_target
    local candidate
    local candidate_target

    grok_agent_target=$(readlink -f "$grok_agent" 2>/dev/null || true)

    for candidate in "$REMOTE_USER_HOME/.local/bin/agent" "$INSTALL_DIR/agent"; do
        candidate_target=$(readlink "$candidate" 2>/dev/null || true)
        if [ "$candidate_target" = "$grok_agent" ] || { [ -n "$grok_agent_target" ] && [ "$(readlink -f "$candidate" 2>/dev/null || true)" = "$grok_agent_target" ]; }; then
            rm -f "$candidate"
        fi
    done

    rm -f "$grok_agent"
}

install_grok() {
    if [ "$INSTALL_GROK" != "true" ]; then
        echo "Skipping Grok installation (disabled)"
        return 0
    fi

    echo "Installing Grok..."

    # Check as the remote user because Grok installs into that user's home.
    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "command -v grok" &>/dev/null; then
            echo "Grok is already installed, skipping"
            remove_grok_agent_aliases
            return 0
        fi
    elif command -v grok &>/dev/null; then
        echo "Grok is already installed, skipping"
        remove_grok_agent_aliases
        return 0
    fi

    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "bash -o pipefail -c 'curl -fsSL https://x.ai/cli/install.sh | bash'"; then
            if [ ! -x "$REMOTE_USER_HOME/.grok/bin/grok" ]; then
                echo "WARNING: Grok installer completed without creating $REMOTE_USER_HOME/.grok/bin/grok" >&2
                remove_grok_agent_aliases
                return 0
            fi
            ln -sf "$REMOTE_USER_HOME/.grok/bin/grok" "$INSTALL_DIR/grok"
            remove_grok_agent_aliases
            echo "Grok installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install Grok" >&2
        fi
    else
        if bash -o pipefail -c 'curl -fsSL https://x.ai/cli/install.sh | bash'; then
            if [ ! -x "$REMOTE_USER_HOME/.grok/bin/grok" ]; then
                echo "WARNING: Grok installer completed without creating $REMOTE_USER_HOME/.grok/bin/grok" >&2
                remove_grok_agent_aliases
                return 0
            fi
            ln -sf "$REMOTE_USER_HOME/.grok/bin/grok" "$INSTALL_DIR/grok"
            remove_grok_agent_aliases
            echo "Grok installed successfully"
        else
            echo "WARNING: Failed to install Grok" >&2
        fi
    fi

    return 0
}

# Install Cursor Agent CLI
install_cursor() {
    if [ "$INSTALL_CURSOR" != "true" ]; then
        echo "Skipping Cursor Agent installation (disabled)"
        return 0
    fi

    echo "Installing Cursor Agent..."

    local cursor_agent="$REMOTE_USER_HOME/.local/bin/agent"
    local cursor_install_dir="$REMOTE_USER_HOME/.local/share/cursor-agent"

    if [ -x "$cursor_agent" ] && [ -d "$cursor_install_dir" ]; then
        ln -sf "$cursor_agent" "$INSTALL_DIR/agent"
        echo "Cursor Agent is already installed, skipping"
        return 0
    fi

    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "bash -o pipefail -c 'curl https://cursor.com/install -fsS | bash'"; then
            if [ ! -x "$cursor_agent" ]; then
                echo "WARNING: Cursor installer completed without creating $cursor_agent" >&2
                return 0
            fi
            ln -sf "$cursor_agent" "$INSTALL_DIR/agent"
            echo "Cursor Agent installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install Cursor Agent" >&2
        fi
    else
        if bash -o pipefail -c 'curl https://cursor.com/install -fsS | bash'; then
            if [ ! -x "$cursor_agent" ]; then
                echo "WARNING: Cursor installer completed without creating $cursor_agent" >&2
                return 0
            fi
            ln -sf "$cursor_agent" "$INSTALL_DIR/agent"
            echo "Cursor Agent installed successfully"
        else
            echo "WARNING: Failed to install Cursor Agent" >&2
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

# Install 1Password CLI from the official apt repository
install_op() {
    if [ "$INSTALL_OP" != "true" ]; then
        echo "Skipping 1Password CLI installation (disabled)"
        return 0
    fi

    echo "Installing 1Password CLI..."

    if command -v op &>/dev/null; then
        echo "1Password CLI is already installed, skipping"
        return 0
    fi

    if ! is_debian_or_ubuntu; then
        echo "ERROR: installOp requires a Debian/Ubuntu based image. Set installOp=false to skip it." >&2
        return 1
    fi

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl gnupg

    local dpkg_arch
    dpkg_arch="$(dpkg --print-architecture)"

    curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
        | gpg --dearmor --yes --output /usr/share/keyrings/1password-archive-keyring.gpg

    echo "deb [arch=${dpkg_arch} signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/${dpkg_arch} stable main" \
        > /etc/apt/sources.list.d/1password.list

    mkdir -p /etc/debsig/policies/AC2D62742012EA22 /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -fsSL https://downloads.1password.com/linux/debian/debsig/1password.pol \
        -o /etc/debsig/policies/AC2D62742012EA22/1password.pol
    curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
        | gpg --dearmor --yes --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

    apt-get update
    apt-get install -y --no-install-recommends 1password-cli
    apt-get clean
    rm -rf /var/lib/apt/lists/*

    echo "1Password CLI installed successfully"
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

    local pi_arch
    if [ "$ARCH" = "amd64" ]; then
        pi_arch="x64"
    elif [ "$ARCH" = "arm64" ]; then
        pi_arch="arm64"
    else
        echo "WARNING: Unsupported architecture for pi: $ARCH" >&2
        return 0
    fi

    local url="https://github.com/earendil-works/pi/releases/latest/download/pi-linux-${pi_arch}.tar.gz"
    local tmpdir
    tmpdir=$(mktemp -d)

    if ! download_file "$url" "$tmpdir/pi.tar.gz"; then
        echo "WARNING: Failed to download pi" >&2
        rm -rf "$tmpdir"
        return 0
    fi

    tar -xzf "$tmpdir/pi.tar.gz" -C "$tmpdir"
    rm -rf /opt/pi
    mkdir -p /opt/pi
    cp -a "$tmpdir/pi/." /opt/pi/
    chmod 755 /opt/pi/pi
    ln -sf /opt/pi/pi "$INSTALL_DIR/pi"
    rm -rf "$tmpdir"

    echo "pi installed successfully"

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

# Install witr process tracing CLI and TUI
install_witr() {
    if [ "$INSTALL_WITR" != "true" ]; then
        echo "Skipping witr installation (disabled)"
        return 0
    fi

    echo "Installing witr..."

    if command -v witr &>/dev/null; then
        echo "witr is already installed, skipping"
        return 0
    fi

    if curl -fsSL https://raw.githubusercontent.com/pranshuparmar/witr/main/install.sh | bash; then
        echo "witr installed successfully"
    else
        echo "WARNING: Failed to install witr" >&2
    fi

    return 0
}

# Install Oh My Pi coding agent
install_oh_my_pi() {
    if [ "$INSTALL_OH_MY_PI" != "true" ]; then
        echo "Skipping Oh My Pi installation (disabled)"
        return 0
    fi

    echo "Installing Oh My Pi..."

    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "command -v omp" &>/dev/null; then
            echo "Oh My Pi is already installed, skipping"
            return 0
        fi
    elif command -v omp &>/dev/null; then
        echo "Oh My Pi is already installed, skipping"
        return 0
    fi

    if command -v apk &>/dev/null; then
        apk add --no-cache libstdc++ libgcc
    fi

    if [ "$REMOTE_USER" != "root" ]; then
        if su - "$REMOTE_USER" -c "curl -fsSL https://omp.sh/install | sh"; then
            link_user_bin "omp" "$REMOTE_USER_HOME"
            echo "Oh My Pi installed successfully for user $REMOTE_USER"
        else
            echo "WARNING: Failed to install Oh My Pi" >&2
        fi
    else
        if curl -fsSL https://omp.sh/install | sh; then
            link_user_bin "omp" "$REMOTE_USER_HOME"
            echo "Oh My Pi installed successfully"
        else
            echo "WARNING: Failed to install Oh My Pi" >&2
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
    echo "  INSTALL_OPENCODE=$INSTALL_OPENCODE"
    echo "  INSTALL_GROK=$INSTALL_GROK"
    echo "  INSTALL_CURSOR=$INSTALL_CURSOR"
    echo "  INSTALL_GH=$INSTALL_GH"
    echo "  INSTALL_OP=$INSTALL_OP"
    echo "  INSTALL_FDSX=$INSTALL_FDSX"
    echo "  INSTALL_RTK=$INSTALL_RTK"
    echo "  INSTALL_WITR=$INSTALL_WITR"
    echo "  INSTALL_PI=$INSTALL_PI"
    echo "  INSTALL_OH_MY_PI=$INSTALL_OH_MY_PI"
    echo "  LAZYGIT_VERSION=$LAZYGIT_VERSION"
    echo "  NVIM_VERSION=$NVIM_VERSION"

    if [ "$ARCH" = "unknown" ]; then
        echo "WARNING: Unknown architecture, some tools may not install correctly" >&2
    fi

    # Create profile.d directory if it doesn't exist
    mkdir -p /etc/profile.d

    install_dependencies
    install_lazygit
    install_nvim
    install_claude_code
    install_codex
    install_opencode
    install_grok
    install_cursor
    install_gh
    install_op
    install_fdsx
    install_rtk
    install_witr
    install_pi
    install_oh_my_pi

    echo "tools feature installation complete"
}

main "$@"
