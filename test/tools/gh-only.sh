#!/bin/bash
set -e

echo "Testing gh-only installation..."

command -v gh &>/dev/null || { echo "FAIL: gh is not installed"; exit 1; }
test -x "$HOME/.local/share/gh/extensions/gh-stack/gh-stack" || { echo "FAIL: gh-stack extension is not installed"; exit 1; }
gh stack --help &>/dev/null || { echo "FAIL: gh-stack command is not usable"; exit 1; }
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v nvim &>/dev/null && { echo "FAIL: nvim should not be installed"; exit 1; }

echo "All tests passed!"
