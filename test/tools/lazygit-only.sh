#!/bin/bash
set -e

echo "Testing lazygit-only installation..."

command -v lazygit &>/dev/null || { echo "FAIL: lazygit is not installed"; exit 1; }
command -v nvim &>/dev/null && { echo "FAIL: nvim should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
