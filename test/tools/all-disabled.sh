#!/bin/bash
set -e

echo "Testing all-disabled installation..."

for tool in lazygit nvim rg fd fzf claude codex gh fdsx rtk pi just direnv tailscale tailscaled sshd; do
    if command -v "$tool" &>/dev/null; then
        echo "FAIL: $tool should not be installed"
        exit 1
    fi
    echo "PASS: $tool is not installed (as expected)"
done

echo "All tests passed!"
