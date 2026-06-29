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
    rm -rf "${tmpdir}"
}
trap cleanup EXIT

mkdir -p "${tmpdir}/bin"

cat > "${tmpdir}/bin/apt-get" <<'EOF'
#!/bin/sh
set -euo pipefail

printf '%s\n' "$*" >> "${TEST_TMPDIR}/apt-get.log"
exit 0
EOF

cat > "${tmpdir}/bin/uname" <<'EOF'
#!/bin/sh
printf 'x86_64\n'
EOF

cat > "${tmpdir}/bin/dirname" <<'EOF'
#!/bin/sh
value="${1%/*}"
if [ "${value}" = "${1}" ]; then
    printf '.\n'
else
    printf '%s\n' "${value}"
fi
EOF

cat > "${tmpdir}/bin/pwd" <<'EOF'
#!/bin/sh
printf '%s\n' "${PWD}"
EOF

cat > "${tmpdir}/bin/mkdir" <<'EOF'
#!/bin/sh
set -euo pipefail

for arg in "$@"; do
    if [ "${arg}" = "/etc/profile.d" ]; then
        exit 0
    fi
done

/bin/mkdir "$@"
EOF

cat > "${tmpdir}/bin/install" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "${tmpdir}/bin/rm" <<'EOF'
#!/bin/sh
exit 0
EOF

chmod +x "${tmpdir}/bin/apt-get" "${tmpdir}/bin/uname" "${tmpdir}/bin/dirname" "${tmpdir}/bin/pwd" "${tmpdir}/bin/mkdir" "${tmpdir}/bin/install" "${tmpdir}/bin/rm"

PATH="${tmpdir}/bin" \
TEST_TMPDIR="${tmpdir}" \
INSTALLLAZYGIT=false \
INSTALLNVIM=false \
INSTALLCLAUDECODE=false \
INSTALLCODEX=false \
INSTALLGH=false \
INSTALLFDSX=false \
INSTALLRTK=false \
INSTALLPI=false \
INSTALLTAILSCALE=false \
INSTALLSSHD=false \
    "${BASH}" "${repo_root}/src/tools/install.sh"

if ! grep -q -- 'install .*build-essential' "${tmpdir}/apt-get.log"; then
    echo "FAIL: build-essential was not requested when build tools were missing"
    cat "${tmpdir}/apt-get.log"
    exit 1
fi

if ! grep -q -- 'install .*python3' "${tmpdir}/apt-get.log"; then
    echo "FAIL: python3 was not requested when build tools were missing"
    cat "${tmpdir}/apt-get.log"
    exit 1
fi

echo "PASS: missing build tools are installed"
