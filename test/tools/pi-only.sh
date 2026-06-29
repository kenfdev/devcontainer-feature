#!/bin/bash
set -e

echo "Testing pi-only installation..."

command -v pi &>/dev/null || { echo "FAIL: pi is not installed"; exit 1; }
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
