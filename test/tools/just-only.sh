#!/bin/bash
set -e

echo "Testing just-only installation..."

command -v just &>/dev/null || { echo "FAIL: just is not installed"; exit 1; }
just --version
command -v direnv &>/dev/null && { echo "FAIL: direnv should not be installed"; exit 1; }
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
