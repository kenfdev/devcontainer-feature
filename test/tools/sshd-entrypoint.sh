#!/usr/bin/env bash
set -euo pipefail

if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    if [ -x /opt/homebrew/bin/bash ]; then
        exec /opt/homebrew/bin/bash "$0" "$@"
    fi

    echo "FAIL: Bash 4 or newer is required for this test" >&2
    exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmpdir="$(mktemp -d)"

cleanup() {
    if [ -f "${tmpdir}/sshd.pid" ]; then
        kill "$(cat "${tmpdir}/sshd.pid")" >/dev/null 2>&1 || true
    fi
    rm -rf "${tmpdir}"
}
trap cleanup EXIT

mkdir -p "${tmpdir}/bin" "${tmpdir}/etc-ssh" "${tmpdir}/home/root"

cat > "${tmpdir}/bin/getent" <<EOF
#!/usr/bin/env bash
set -euo pipefail

if [ "\${1:-}" = "passwd" ] && [ "\${2:-}" = "root" ]; then
    printf 'root:x:0:0:root:${tmpdir}/home/root:/bin/bash\n'
    exit 0
fi

exit 2
EOF

cat > "${tmpdir}/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

cat > "${tmpdir}/bin/ssh-keygen" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-A" ]; then
    mkdir -p "${SSHD_CONFIG_DIR}"
    for type in rsa ecdsa ed25519; do
        printf 'private-%s\n' "${type}" > "${SSHD_CONFIG_DIR}/ssh_host_${type}_key"
        printf 'public-%s\n' "${type}" > "${SSHD_CONFIG_DIR}/ssh_host_${type}_key.pub"
    done
    exit 0
fi

echo "unexpected ssh-keygen invocation: $*" >&2
exit 1
EOF

cat > "${tmpdir}/bin/sshd" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" > "${TEST_TMPDIR}/sshd-start.log"
echo "$$" > "${TEST_TMPDIR}/sshd.pid"

while true; do
    sleep 60
done
EOF

chmod +x "${tmpdir}/bin/getent" "${tmpdir}/bin/pgrep" "${tmpdir}/bin/ssh-keygen" "${tmpdir}/bin/sshd"

PATH="${tmpdir}/bin:${PATH}" \
TEST_TMPDIR="${tmpdir}" \
SSHD_ENABLE=true \
SSHD_CONFIG_DIR="${tmpdir}/etc-ssh" \
SSHD_RUN_DIR="${tmpdir}/run-sshd" \
SSHD_HOST_KEY_DIR="${tmpdir}/host-keys" \
SSH_AUTHORIZED_KEYS="ssh-ed25519 test-key root@example" \
    "${BASH}" "${repo_root}/src/tools/tailscale-entrypoint.sh" sleep 0.2

for _ in {1..20}; do
    [ -f "${tmpdir}/sshd-start.log" ] && break
    sleep 0.1
done

test -f "${tmpdir}/sshd-start.log" || {
    echo "FAIL: sshd was not started"
    exit 1
}

grep -q -- '-D -e' "${tmpdir}/sshd-start.log" || {
    echo "FAIL: sshd was not started in foreground logging mode"
    cat "${tmpdir}/sshd-start.log"
    exit 1
}

test -f "${tmpdir}/host-keys/ssh_host_ed25519_key" || {
    echo "FAIL: persistent SSH host keys were not generated"
    exit 1
}

test -L "${tmpdir}/etc-ssh/ssh_host_ed25519_key" || {
    echo "FAIL: SSH host key was not linked into SSH config dir"
    exit 1
}

grep -q 'ssh-ed25519 test-key root@example' "${tmpdir}/home/root/.ssh/authorized_keys" || {
    echo "FAIL: SSH_AUTHORIZED_KEYS was not written to root authorized_keys"
    exit 1
}

echo "PASS: sshd starts and configures persistent host keys"
