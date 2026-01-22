#!/bin/bash
set -e

# Test codex-only installation - only Codex should be installed
echo "Testing codex-only installation..."

# Test Codex (should be installed)
if command -v codex &>/dev/null; then
    echo "PASS: codex is installed"
else
    echo "FAIL: codex is not installed"
    exit 1
fi

# Test tmux (should NOT be installed)
if command -v tmux &>/dev/null; then
    echo "FAIL: tmux should not be installed"
    exit 1
else
    echo "PASS: tmux is not installed (as expected)"
fi

# Test lazygit (should NOT be installed)
if command -v lazygit &>/dev/null; then
    echo "FAIL: lazygit should not be installed"
    exit 1
else
    echo "PASS: lazygit is not installed (as expected)"
fi

# Test neovim (should NOT be installed)
if command -v nvim &>/dev/null; then
    echo "FAIL: nvim should not be installed"
    exit 1
else
    echo "PASS: nvim is not installed (as expected)"
fi

# Test Claude Code (should NOT be installed)
if command -v claude &>/dev/null; then
    echo "FAIL: claude should not be installed"
    exit 1
else
    echo "PASS: claude is not installed (as expected)"
fi

echo "All tests passed!"
