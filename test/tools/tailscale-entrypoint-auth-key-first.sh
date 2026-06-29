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
    if [ -f "${tmpdir}/tailscaled.pid" ]; then
        kill "$(cat "${tmpdir}/tailscaled.pid")" >/dev/null 2>&1 || true
    fi
    rm -rf "${tmpdir}"
}
trap cleanup EXIT

mkdir -p "${tmpdir}/bin" "${tmpdir}/state"

cat > "${tmpdir}/bin/mkdir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 2 ] && [ "$1" = "-p" ] && [ "$2" = "/dev/net" ]; then
    exit 0
fi

exec /bin/mkdir "$@"
EOF

cat > "${tmpdir}/bin/mknod" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

cat > "${tmpdir}/bin/tailscaled" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

state_dir=""
for arg in "$@"; do
    case "${arg}" in
        --statedir=*)
            state_dir="${arg#--statedir=}"
            ;;
    esac
done

mkdir -p "${state_dir}"
touch "${state_dir}/tailscaled.state"
echo "$$" > "${TEST_TMPDIR}/tailscaled.pid"

while true; do
    sleep 60
done
EOF

cat > "${tmpdir}/bin/tailscale" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

args=("$@")
command_name=""
for arg in "${args[@]}"; do
    case "${arg}" in
        --socket=*)
            ;;
        status|up|logout)
            command_name="${arg}"
            break
            ;;
    esac
done

case "${command_name}" in
    status)
        touch "${TEST_TMPDIR}/state/pre-login.state"
        exit 0
        ;;
    up)
        printf '%s\n' "$*" >> "${TEST_TMPDIR}/tailscale-up.log"
        exit 0
        ;;
    logout)
        exit 0
        ;;
    *)
        echo "unexpected tailscale invocation: $*" >&2
        exit 1
        ;;
esac
EOF

chmod +x "${tmpdir}/bin/mkdir" "${tmpdir}/bin/mknod" "${tmpdir}/bin/tailscaled" "${tmpdir}/bin/tailscale"

PATH="${tmpdir}/bin:${PATH}" \
TEST_TMPDIR="${tmpdir}" \
TS_STATE_DIR="${tmpdir}/state" \
TS_SOCKET="${tmpdir}/tailscaled.sock" \
TS_AUTH_KEY="tskey-auth-test" \
TS_ENABLE_SSH=false \
TS_TAG= \
    "${BASH}" "${repo_root}/src/tools/tailscale-entrypoint.sh" true

if ! grep -q -- '--auth-key=tskey-auth-test' "${tmpdir}/tailscale-up.log"; then
    echo "FAIL: first tailscale up did not use TS_AUTH_KEY when pre-login state existed"
    echo "Recorded invocations:"
    cat "${tmpdir}/tailscale-up.log"
    exit 1
fi

echo "PASS: tailscale entrypoint uses TS_AUTH_KEY before state-only login"
