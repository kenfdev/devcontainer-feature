#!/bin/bash
set -e

echo "Testing mise-only installation..."

command -v mise &>/dev/null || { echo "FAIL: mise is not installed"; exit 1; }
mise --version
test -r /etc/profile.d/mise.sh || { echo "FAIL: mise profile script is missing"; exit 1; }
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
