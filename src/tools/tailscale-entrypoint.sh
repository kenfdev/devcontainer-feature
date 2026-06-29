#!/usr/bin/env bash
set -Eeuo pipefail

log() {
    echo "tailscale-entrypoint: $*" >&2
}

TS_STATE_DIR="${TS_STATE_DIR:-/var/lib/tailscale}"
TS_SOCKET="${TS_SOCKET:-/var/run/tailscale/tailscaled.sock}"
TS_ENABLE_SSH="${TS_ENABLE_SSH:-true}"
TS_ACCEPT_ROUTES="${TS_ACCEPT_ROUTES:-false}"
TS_RESET_ON_AUTH_FAILURE="${TS_RESET_ON_AUTH_FAILURE:-false}"
SSHD_ENABLE="${SSHD_ENABLE:-true}"
SSHD_USER="${SSHD_USER:-root}"
SSHD_HOST_KEY_DIR="${SSHD_HOST_KEY_DIR:-/var/lib/ssh-host-keys}"
SSHD_CONFIG_DIR="${SSHD_CONFIG_DIR:-/etc/ssh}"
SSHD_RUN_DIR="${SSHD_RUN_DIR:-/run/sshd}"

AUTH_KEY="${TS_AUTH_KEY:-${TS_AUTHKEY:-}}"
unset TS_AUTH_KEY TS_AUTHKEY

HOSTNAME_VALUE="${TS_HOSTNAME:-$(hostname)}"

sshd_bin() {
    if command -v sshd >/dev/null 2>&1; then
        command -v sshd
        return 0
    fi

    if [ -x /usr/sbin/sshd ]; then
        echo /usr/sbin/sshd
        return 0
    fi

    return 1
}

ensure_sshd_host_keys() {
    mkdir -p "${SSHD_CONFIG_DIR}" "${SSHD_HOST_KEY_DIR}"

    if ! find "${SSHD_HOST_KEY_DIR}" -maxdepth 1 -name 'ssh_host_*_key' -type f -print -quit 2>/dev/null | grep -q .; then
        ssh-keygen -A
        cp -a "${SSHD_CONFIG_DIR}"/ssh_host_*_key "${SSHD_CONFIG_DIR}"/ssh_host_*_key.pub "${SSHD_HOST_KEY_DIR}"/ 2>/dev/null || true
    fi

    local key_path key_name
    for key_path in "${SSHD_HOST_KEY_DIR}"/ssh_host_*_key; do
        [ -f "${key_path}" ] || continue
        key_name="$(basename "${key_path}")"
        ln -sf "${key_path}" "${SSHD_CONFIG_DIR}/${key_name}"
        if [ -f "${key_path}.pub" ]; then
            ln -sf "${key_path}.pub" "${SSHD_CONFIG_DIR}/${key_name}.pub"
        fi
    done
}

configure_authorized_keys() {
    local user_home authorized_keys_file
    user_home="$(getent passwd "${SSHD_USER}" 2>/dev/null | cut -d: -f6 || true)"
    if [ -z "${user_home}" ]; then
        user_home="/root"
    fi

    mkdir -p "${user_home}/.ssh"
    chmod 700 "${user_home}/.ssh"
    authorized_keys_file="${user_home}/.ssh/authorized_keys"

    if [ -n "${SSH_AUTHORIZED_KEYS:-}" ]; then
        printf '%s\n' "${SSH_AUTHORIZED_KEYS}" > "${authorized_keys_file}"
    elif [ -n "${SSH_AUTHORIZED_KEYS_FILE:-}" ] && [ -r "${SSH_AUTHORIZED_KEYS_FILE}" ]; then
        cp "${SSH_AUTHORIZED_KEYS_FILE}" "${authorized_keys_file}"
    fi

    if [ -f "${authorized_keys_file}" ]; then
        chmod 600 "${authorized_keys_file}"
        chown -R "${SSHD_USER}:${SSHD_USER}" "${user_home}/.ssh" 2>/dev/null || true
    fi
}

start_sshd() {
    local sshd_path

    if [ "${SSHD_ENABLE}" != "true" ]; then
        return 0
    fi

    if ! sshd_path="$(sshd_bin)"; then
        return 0
    fi

    mkdir -p "${SSHD_RUN_DIR}"
    ensure_sshd_host_keys
    configure_authorized_keys

    if pgrep -x sshd >/dev/null 2>&1; then
        return 0
    fi

    "${sshd_path}" -D -e &
}

ensure_tun_device() {
    if [ -c /dev/net/tun ]; then
        return 0
    fi

    mkdir -p /dev/net
    if mknod /dev/net/tun c 10 200 2>/dev/null; then
        chmod 600 /dev/net/tun
        return 0
    fi

    log "WARNING: /dev/net/tun is missing and could not be created. Add MKNOD and mount /dev/net/tun when using Docker/Compose."
}

wait_for_tailscaled() {
    local attempts=0
    while [ "${attempts}" -lt 50 ]; do
        if tailscale --socket="${TS_SOCKET}" status >/dev/null 2>&1; then
            return 0
        fi
        if [ -S "${TS_SOCKET}" ]; then
            return 0
        fi
        attempts=$((attempts + 1))
        sleep 0.1
    done

    log "WARNING: tailscaled did not become ready in time"
    return 1
}

start_tailscaled() {
    mkdir -p "${TS_STATE_DIR}" "$(dirname "${TS_SOCKET}")"

    if pgrep -x tailscaled >/dev/null 2>&1; then
        return 0
    fi

    tailscaled \
        --socket="${TS_SOCKET}" \
        --statedir="${TS_STATE_DIR}" &

    wait_for_tailscaled || true
}

backend_state() {
    tailscale --socket="${TS_SOCKET}" status --json 2>/dev/null \
        | sed -n 's/.*"BackendState":[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n 1
}

has_existing_state() {
    find "${TS_STATE_DIR}" -mindepth 1 -type f -print -quit 2>/dev/null | grep -q .
}

tailscale_up_args() {
    local -n out_args=$1

    out_args=(
        --hostname="${HOSTNAME_VALUE}"
    )

    if [ -n "${TS_TAG:-}" ]; then
        out_args+=(--advertise-tags="${TS_TAG}")
    fi

    if [ "${TS_ENABLE_SSH}" = "true" ]; then
        out_args+=(--ssh)
    fi

    if [ "${TS_ACCEPT_ROUTES}" = "true" ]; then
        out_args+=(--accept-routes)
    fi

    if [ -n "${TS_EXTRA_ARGS:-}" ]; then
        local extra_args=()
        read -r -a extra_args <<< "${TS_EXTRA_ARGS}"
        out_args+=("${extra_args[@]}")
    fi
}

run_tailscale_up() {
    local auth_key="${1:-}"
    local args=()

    tailscale_up_args args

    if [ -n "${auth_key}" ]; then
        args+=(--reset)
        args+=(--auth-key="${auth_key}")
    fi

    tailscale --socket="${TS_SOCKET}" up "${args[@]}"
}

reset_tailscale_state() {
    log "Resetting Tailscale state after authentication failure"
    tailscale --socket="${TS_SOCKET}" logout >/dev/null 2>&1 || true

    if [ -z "${TS_STATE_DIR}" ] || [ "${TS_STATE_DIR}" = "/" ]; then
        log "WARNING: Refusing to clear unsafe TS_STATE_DIR='${TS_STATE_DIR}'"
        return 0
    fi

    find "${TS_STATE_DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
}

bring_tailscale_up() {
    local state
    state="$(backend_state || true)"

    if [ "${state}" = "Running" ]; then
        if run_tailscale_up ""; then
            return 0
        fi
        log "WARNING: Failed to refresh Tailscale settings with existing login"
    fi

    if [ -n "${AUTH_KEY}" ]; then
        if run_tailscale_up "${AUTH_KEY}"; then
            return 0
        fi

        if [ "${TS_RESET_ON_AUTH_FAILURE}" = "true" ]; then
            reset_tailscale_state
            run_tailscale_up "${AUTH_KEY}" || log "WARNING: Tailscale authentication failed after reset; continuing container startup"
            return 0
        fi

        log "WARNING: Tailscale authentication failed; continuing container startup"
        return 0
    fi

    if has_existing_state; then
        if run_tailscale_up ""; then
            return 0
        fi
        log "WARNING: Failed to bring Tailscale up with existing state"
        return 0
    fi

    log "WARNING: No TS_AUTH_KEY or TS_AUTHKEY provided; container will continue without joining Tailscale"
}

start_sshd

if command -v tailscaled >/dev/null 2>&1 && command -v tailscale >/dev/null 2>&1; then
    ensure_tun_device
    start_tailscaled
    bring_tailscale_up
fi

exec "$@"
