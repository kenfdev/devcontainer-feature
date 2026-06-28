#!/bin/bash
set -e

echo "Testing all-disabled installation..."

for tool in lazygit nvim rg fd fzf claude codex gh fdsx rtk pi; do
    if command -v "$tool" &>/dev/null; then
        echo "FAIL: $tool should not be installed"
        exit 1
    fi
    echo "PASS: $tool is not installed (as expected)"
done

if [ -x /usr/sbin/sshd ]; then
    echo "FAIL: sshd should not be installed"
    exit 1
fi

if id dev &>/dev/null; then
    echo "FAIL: dev user should not be created"
    exit 1
fi

echo "All tests passed!"
