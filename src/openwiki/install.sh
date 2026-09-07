#!/bin/bash
set -e

echo "Installing OpenWiki CLI..."

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo "ERROR: Node.js and npm are required to install OpenWiki." >&2
    exit 1
fi

node_major="$(node --version | sed -E 's/^v([0-9]+).*/\1/')"
if ! [[ "$node_major" =~ ^[0-9]+$ ]] || [ "$node_major" -lt 22 ]; then
    echo "ERROR: OpenWiki requires Node.js 22 or newer; found $(node --version)." >&2
    exit 1
fi

npm install -g openwiki

echo "OpenWiki CLI installed successfully."
