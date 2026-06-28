#!/bin/bash
set -e

echo "Testing pinned-versions installation..."

for tool in lazygit nvim rg fd fzf gh; do
    command -v "$tool" &>/dev/null || { echo "FAIL: $tool is not installed"; exit 1; }
done

echo "All tests passed!"
