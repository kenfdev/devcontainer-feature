#!/bin/bash
set -e

echo "Testing witr-only installation..."

command -v witr &>/dev/null || { echo "FAIL: witr is not installed"; exit 1; }
witr --version
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
