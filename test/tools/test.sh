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
check "tailscale entrypoint is installed" test -x /usr/local/bin/tailscale-entrypoint.sh
check "tailscale is not installed by default" sh -c '! command -v tailscale >/dev/null'
check "tailscaled is not installed by default" sh -c '! command -v tailscaled >/dev/null'
check "sshd is installed" sh -c 'command -v sshd >/dev/null || test -x /usr/sbin/sshd'
check "python3 is installed" python3 --version
check "make is installed" make --version
check "C++ compiler is installed" sh -c 'command -v g++ >/dev/null || command -v clang++ >/dev/null'

# Report result
reportResults
