#!/bin/bash
set -e

# Test default installation - all tools should be installed
echo "Testing default installation..."

# Test lazygit
if command -v lazygit &>/dev/null; then
    echo "PASS: lazygit is installed"
else
    echo "FAIL: lazygit is not installed"
    exit 1
fi

# Test neovim
if command -v nvim &>/dev/null; then
    echo "PASS: nvim is installed"
else
    echo "FAIL: nvim is not installed"
    exit 1
fi

# Test ripgrep
if command -v rg &>/dev/null; then
    echo "PASS: ripgrep (rg) is installed"
else
    echo "FAIL: ripgrep (rg) is not installed"
    exit 1
fi

# Test fd
if command -v fd &>/dev/null; then
    echo "PASS: fd is installed"
else
    echo "FAIL: fd is not installed"
    exit 1
fi

# Test fzf
if command -v fzf &>/dev/null; then
    echo "PASS: fzf is installed"
else
    echo "FAIL: fzf is not installed"
    exit 1
fi

# Test tmux
if command -v tmux &>/dev/null; then
    echo "PASS: tmux is installed"
else
    echo "FAIL: tmux is not installed"
    exit 1
fi

echo "All tests passed!"
