#!/bin/bash
set -e

echo "Testing Grok and Cursor command ownership..."

grok --version &>/dev/null || { echo "FAIL: grok cannot run"; exit 1; }
agent --version &>/dev/null || { echo "FAIL: Cursor agent cannot run"; exit 1; }
[ ! -e "$HOME/.grok/bin/agent" ] && [ ! -L "$HOME/.grok/bin/agent" ] || { echo "FAIL: Grok agent alias should be absent"; exit 1; }
[ "$(readlink -f /usr/local/bin/agent)" = "$(readlink -f "$HOME/.local/bin/agent")" ] || { echo "FAIL: agent should resolve to Cursor"; exit 1; }

echo "All tests passed!"
