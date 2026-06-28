#!/bin/bash
set -e

echo "Testing claude-code-only installation..."

command -v claude &>/dev/null || { echo "FAIL: claude is not installed"; exit 1; }
command -v codex &>/dev/null && { echo "FAIL: codex should not be installed"; exit 1; }
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }

echo "All tests passed!"
