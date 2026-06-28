#!/bin/bash
set -e

echo "Testing nvim-only installation..."

for tool in nvim rg fd fzf; do
    command -v "$tool" &>/dev/null || { echo "FAIL: $tool is not installed"; exit 1; }
done

command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
