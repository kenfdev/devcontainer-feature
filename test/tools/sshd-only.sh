#!/bin/bash
set -e

echo "Testing sshd-only installation..."

command -v sshd >/dev/null || test -x /usr/sbin/sshd || { echo "FAIL: sshd is not installed"; exit 1; }
test -x /usr/local/bin/tailscale-entrypoint.sh || { echo "FAIL: tailscale entrypoint is not executable"; exit 1; }

command -v tailscale >/dev/null && { echo "FAIL: tailscale should not be installed"; exit 1; }
command -v tailscaled >/dev/null && { echo "FAIL: tailscaled should not be installed"; exit 1; }
command -v lazygit >/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh >/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
