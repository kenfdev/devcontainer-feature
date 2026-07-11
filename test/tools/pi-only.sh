#!/bin/bash
set -e

echo "Testing pi-only installation..."

command -v pi &>/dev/null || { echo "FAIL: pi is not installed"; exit 1; }
pi --version &>/dev/null || { echo "FAIL: pi cannot run"; exit 1; }

node_major=$(node --version | cut -d. -f1)
[ "$node_major" = "v20" ] || { echo "FAIL: pi installation changed Node.js to $(node --version)"; exit 1; }

npm_prefix=$(npm config get prefix)
[ "$npm_prefix" = "/usr/local/share/npm-global" ] || { echo "FAIL: pi installation changed npm prefix to $npm_prefix"; exit 1; }

command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
