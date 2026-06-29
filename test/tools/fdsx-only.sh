#!/bin/bash
set -e

echo "Testing fdsx-only installation..."

command -v fdsx &>/dev/null || { echo "FAIL: fdsx is not installed"; exit 1; }
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
