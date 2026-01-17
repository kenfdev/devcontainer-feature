#!/bin/bash
set -e

# Test nvim-only installation - only neovim and supporting tools should be installed
echo "Testing nvim-only installation..."

# Test neovim (should be installed)
if command -v nvim &>/dev/null; then
    echo "PASS: nvim is installed"
else
    echo "FAIL: nvim is not installed"
    exit 1
fi

# Test ripgrep (should be installed - it's a neovim supporting tool)
if command -v rg &>/dev/null; then
    echo "PASS: ripgrep (rg) is installed"
else
    echo "FAIL: ripgrep (rg) is not installed"
    exit 1
fi

# Test fd (should be installed - it's a neovim supporting tool)
if command -v fd &>/dev/null; then
    echo "PASS: fd is installed"
else
    echo "FAIL: fd is not installed"
    exit 1
fi

# Test fzf (should be installed - it's a neovim supporting tool)
if command -v fzf &>/dev/null; then
    echo "PASS: fzf is installed"
else
    echo "FAIL: fzf is not installed"
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

echo "All tests passed!"
