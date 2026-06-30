#!/bin/bash
set -e

echo "Testing direnv-only installation..."

command -v direnv &>/dev/null || { echo "FAIL: direnv is not installed"; exit 1; }
direnv version
command -v just &>/dev/null && { echo "FAIL: just should not be installed"; exit 1; }
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
