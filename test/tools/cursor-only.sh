#!/bin/bash
set -e

echo "Testing cursor-only installation..."

command -v agent &>/dev/null || { echo "FAIL: Cursor agent is not installed"; exit 1; }
agent --version &>/dev/null || { echo "FAIL: Cursor agent cannot run"; exit 1; }
command -v grok &>/dev/null && { echo "FAIL: grok should not be installed"; exit 1; }

echo "All tests passed!"
