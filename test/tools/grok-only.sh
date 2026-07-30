#!/bin/bash
set -e

echo "Testing grok-only installation..."

command -v grok &>/dev/null || { echo "FAIL: grok is not installed"; exit 1; }
grok --version &>/dev/null || { echo "FAIL: grok cannot run"; exit 1; }
[ ! -e "$HOME/.grok/bin/agent" ] && [ ! -L "$HOME/.grok/bin/agent" ] || { echo "FAIL: Grok agent alias should be absent"; exit 1; }
command -v agent &>/dev/null && { echo "FAIL: agent should not be installed"; exit 1; }

command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v nvim &>/dev/null && { echo "FAIL: nvim should not be installed"; exit 1; }
command -v claude &>/dev/null && { echo "FAIL: claude should not be installed"; exit 1; }
command -v codex &>/dev/null && { echo "FAIL: codex should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }
command -v op &>/dev/null && { echo "FAIL: op should not be installed"; exit 1; }
command -v fdsx &>/dev/null && { echo "FAIL: fdsx should not be installed"; exit 1; }
command -v rtk &>/dev/null && { echo "FAIL: rtk should not be installed"; exit 1; }
command -v pi &>/dev/null && { echo "FAIL: pi should not be installed"; exit 1; }

echo "All tests passed!"
