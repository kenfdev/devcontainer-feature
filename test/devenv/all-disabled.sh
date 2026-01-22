#!/bin/bash
set -e

# Test all-disabled installation - no tools should be installed
echo "Testing all-disabled installation..."

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

# Test ripgrep (should NOT be installed - it's a neovim supporting tool)
if command -v rg &>/dev/null; then
    echo "FAIL: ripgrep should not be installed"
    exit 1
else
    echo "PASS: ripgrep is not installed (as expected)"
fi

# Test fd (should NOT be installed - it's a neovim supporting tool)
if command -v fd &>/dev/null; then
    echo "FAIL: fd should not be installed"
    exit 1
else
    echo "PASS: fd is not installed (as expected)"
fi

# Test fzf (should NOT be installed - it's a neovim supporting tool)
if command -v fzf &>/dev/null; then
    echo "FAIL: fzf should not be installed"
    exit 1
else
    echo "PASS: fzf is not installed (as expected)"
fi

# Test Claude Code (should NOT be installed)
if command -v claude &>/dev/null; then
    echo "FAIL: claude should not be installed"
    exit 1
else
    echo "PASS: claude is not installed (as expected)"
fi

# Test Codex (should NOT be installed)
if command -v codex &>/dev/null; then
    echo "FAIL: codex should not be installed"
    exit 1
else
    echo "PASS: codex is not installed (as expected)"
fi

echo "All tests passed!"
