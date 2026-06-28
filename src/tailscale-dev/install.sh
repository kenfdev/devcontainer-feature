#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -r /etc/os-release ]; then
    echo "ERROR: Cannot detect Linux distribution. tailscale-dev supports Debian/Ubuntu images only." >&2
    exit 1
fi

# shellcheck source=/dev/null
. /etc/os-release

case "${ID:-}:${ID_LIKE:-}" in
    debian:*|ubuntu:*|*:debian*|*:ubuntu*)
        ;;
    *)
        echo "ERROR: Unsupported distribution '${PRETTY_NAME:-unknown}'. tailscale-dev supports Debian/Ubuntu images only." >&2
        exit 1
        ;;
esac

export DEBIAN_FRONTEND=noninteractive

echo "Installing tailscale-dev dependencies..."
apt-get update
apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    iproute2 \
    iptables \
    procps

echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

install -m 755 "${SCRIPT_DIR}/tailscale-entrypoint.sh" /usr/local/bin/tailscale-entrypoint.sh

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "tailscale-dev installation complete"
