#!/bin/bash
set -e

# Test pi-only installation
echo "Testing pi-only installation..."

# Test pi (installed under the remote user's ~/.local/bin when npm's global directory is not writable)
if command -v pi &>/dev/null; then
    echo "PASS: pi is installed"
elif [ -x /home/vscode/.local/bin/pi ]; then
    echo "PASS: pi is installed for vscode"
else
    echo "FAIL: pi is not installed"
    exit 1
fi

echo "All tests passed!"
