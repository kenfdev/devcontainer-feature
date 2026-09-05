#!/bin/bash
set -e

echo "Testing opencode-only installation..."

command -v opencode &>/dev/null || { echo "FAIL: opencode is not installed"; exit 1; }
opencode --version
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v nvim &>/dev/null && { echo "FAIL: nvim should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }
command -v op &>/dev/null && { echo "FAIL: op should not be installed"; exit 1; }

echo "All tests passed!"
