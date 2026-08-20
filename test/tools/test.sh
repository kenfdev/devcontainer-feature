#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'tools' Feature with no options (all defaults).
#
# These scripts are run as 'root' by default. Although that can be changed
# with the '--remote-user' flag.

set -e

source dev-container-features-test-lib

# Check core tools installed by default
check "lazygit is installed" lazygit --version
check "nvim is installed" nvim --version
check "gh is installed" gh --version
check "op is installed" op --version
check "grok is installed" grok --version
check "Cursor agent is installed" agent --version
check "witr is installed" witr --version
check "Grok agent alias is absent" bash -c '! test -e "$HOME/.grok/bin/agent" && ! test -L "$HOME/.grok/bin/agent"'
check "codex is not installed" bash -c '! command -v codex >/dev/null 2>&1'

# Report result
reportResults
