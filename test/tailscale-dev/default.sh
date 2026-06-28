#!/bin/bash
set -e

echo "Testing tailscale-dev default scenario..."

command -v tailscale >/dev/null || { echo "FAIL: tailscale is not installed"; exit 1; }
command -v tailscaled >/dev/null || { echo "FAIL: tailscaled is not installed"; exit 1; }
test -x /usr/local/bin/tailscale-entrypoint.sh || { echo "FAIL: entrypoint is not executable"; exit 1; }
test -d /var/lib/tailscale || { echo "FAIL: state directory does not exist"; exit 1; }

echo "All tests passed!"
