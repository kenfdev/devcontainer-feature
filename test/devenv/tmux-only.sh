#!/bin/bash
set -e

# Test tmux-only installation - only tmux should be installed
echo "Testing tmux-only installation..."

# Test tmux (should be installed)
if command -v tmux &>/dev/null; then
    echo "PASS: tmux is installed"
else
    echo "FAIL: tmux is not installed"
    exit 1
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

echo "All tests passed!"
