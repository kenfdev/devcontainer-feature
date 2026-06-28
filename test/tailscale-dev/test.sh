#!/bin/bash
set -e

source dev-container-features-test-lib

check "tailscale is installed" tailscale version
check "tailscaled is installed" tailscaled --version
check "entrypoint is installed" test -x /usr/local/bin/tailscale-entrypoint.sh
check "state directory exists" test -d /var/lib/tailscale

reportResults
