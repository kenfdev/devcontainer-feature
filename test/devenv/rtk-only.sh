#!/bin/bash
set -e

# Test rtk-only installation
echo "Testing rtk-only installation..."

# Test rtk
if command -v rtk &>/dev/null; then
    echo "PASS: rtk is installed"
else
    echo "FAIL: rtk is not installed"
    exit 1
fi

echo "All tests passed!"
