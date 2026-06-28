#!/bin/bash
set -e

echo "Testing codex-only installation..."

command -v codex &>/dev/null || { echo "FAIL: codex is not installed"; exit 1; }
command -v claude &>/dev/null && { echo "FAIL: claude should not be installed"; exit 1; }
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }

echo "All tests passed!"
