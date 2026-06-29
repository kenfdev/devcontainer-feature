#!/bin/bash
set -e

echo "Testing build-tools-only installation..."

command -v python3 >/dev/null || { echo "FAIL: python3 is not installed"; exit 1; }
command -v make >/dev/null || { echo "FAIL: make is not installed"; exit 1; }
command -v g++ >/dev/null || command -v clang++ >/dev/null || { echo "FAIL: C++ compiler is not installed"; exit 1; }

command -v tailscale >/dev/null && { echo "FAIL: tailscale should not be installed"; exit 1; }
command -v tailscaled >/dev/null && { echo "FAIL: tailscaled should not be installed"; exit 1; }
command -v sshd >/dev/null && { echo "FAIL: sshd should not be installed"; exit 1; }
command -v lazygit >/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh >/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
