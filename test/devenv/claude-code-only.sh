#!/bin/bash
set -e

# Test claude-code-only installation - only Claude Code should be installed
echo "Testing claude-code-only installation..."

# Test Claude Code (should be installed)
if command -v claude &>/dev/null; then
    echo "PASS: claude is installed"
else
    echo "FAIL: claude is not installed"
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

# Test codex (should NOT be installed)
if command -v codex &>/dev/null; then
    echo "FAIL: codex should not be installed"
    exit 1
else
    echo "PASS: codex is not installed (as expected)"
fi

echo "All tests passed!"
