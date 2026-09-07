#!/bin/bash
set -e

source dev-container-features-test-lib

check "Node.js 22 or newer is installed" node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 22 ? 0 : 1)'
check "OpenWiki CLI is installed" openwiki --help

reportResults
