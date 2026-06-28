#!/bin/bash
set -e

echo "Testing ssh-only installation..."

test -x /usr/sbin/sshd || { echo "FAIL: sshd is not installed"; exit 1; }
/usr/sbin/sshd -t || { echo "FAIL: sshd_config is invalid"; exit 1; }
id dev &>/dev/null || { echo "FAIL: dev user does not exist"; exit 1; }
test -d /home/dev/.ssh || { echo "FAIL: /home/dev/.ssh does not exist"; exit 1; }
grep -q '^AllowUsers dev$' /etc/ssh/sshd_config || { echo "FAIL: sshd_config does not allow dev"; exit 1; }
grep -q '^PasswordAuthentication no$' /etc/ssh/sshd_config || { echo "FAIL: password auth should be disabled"; exit 1; }
grep -q '^PubkeyAuthentication yes$' /etc/ssh/sshd_config || { echo "FAIL: public-key auth should be enabled"; exit 1; }

command -v lazygit &>/dev/null && { echo "FAIL: lazygit should not be installed"; exit 1; }
command -v gh &>/dev/null && { echo "FAIL: gh should not be installed"; exit 1; }

echo "All tests passed!"
