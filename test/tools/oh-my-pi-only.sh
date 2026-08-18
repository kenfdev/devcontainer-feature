#!/bin/bash
set -e

echo "Testing oh-my-pi-only installation..."

command -v omp &>/dev/null || { echo "FAIL: omp is not installed"; exit 1; }
omp --version &>/dev/null || { echo "FAIL: omp cannot run"; exit 1; }

command -v pi &>/dev/null && { echo "FAIL: pi should not be installed"; exit 1; }
command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
