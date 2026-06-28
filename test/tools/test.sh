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
check "codex is installed" codex --version
check "sshd config is valid" /usr/sbin/sshd -t
check "dev user exists" id dev

# Report result
reportResults
