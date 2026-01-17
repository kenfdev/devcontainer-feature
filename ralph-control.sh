#!/bin/bash
# Ralph Control Script - Management Interface for Ralph Loop
# Usage: ./ralph-control.sh [start|stop|kill|status|logs|sessions]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$SCRIPT_DIR/.ralph-state"
PID_FILE="$STATE_DIR/ralph.pid"
LOG_FILE="$STATE_DIR/logs/ralph.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" &>/dev/null; then
            return 0
        fi
    fi
    return 1
}

cmd_start() {
    if is_running; then
        log_error "Ralph is already running (PID: $(cat "$PID_FILE"))"
        exit 1
    fi

    # Remove any stale stop signal
    rm -f "$STATE_DIR/STOP"

    log_info "Starting Ralph in background..."
    nohup "$SCRIPT_DIR/ralph.sh" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"
    log_info "Ralph started with PID: $pid"
    log_info "Use './ralph-control.sh logs' to follow progress"
}

cmd_stop() {
    if ! is_running; then
        log_warn "Ralph is not running"
        exit 0
    fi

    log_info "Sending graceful stop signal..."
    echo "Stopped by ralph-control.sh at $(date)" > "$STATE_DIR/STOP"
    log_info "Stop signal created. Ralph will stop after current iteration completes."
    log_info "Use './ralph-control.sh status' to check progress"
}

cmd_kill() {
    if ! is_running; then
        log_warn "Ralph is not running"
        rm -f "$PID_FILE"
        exit 0
    fi

    local pid
    pid=$(cat "$PID_FILE")
    log_warn "Force killing Ralph (PID: $pid)..."
    kill -9 "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    log_info "Ralph killed"
}

cmd_status() {
    echo "=== Ralph Status ==="
    echo

    if is_running; then
        echo -e "Process: ${GREEN}RUNNING${NC} (PID: $(cat "$PID_FILE"))"
    else
        echo -e "Process: ${RED}STOPPED${NC}"
    fi

    if [[ -f "$STATE_DIR/STOP" ]]; then
        echo -e "Stop Signal: ${YELLOW}PRESENT${NC}"
    else
        echo "Stop Signal: None"
    fi

    echo

    if [[ -f "$STATE_DIR/status.yaml" ]]; then
        echo "=== Operational Status ==="
        cat "$STATE_DIR/status.yaml"
        echo
    fi

    if [[ -f "$STATE_DIR/goals.yaml" ]]; then
        echo "=== Goals Summary ==="
        grep -E "^  (test_|shellcheck)" "$STATE_DIR/goals.yaml" | head -20
        echo
    fi

    # Show recent tickets
    echo "=== Ready Tickets ==="
    bd ready 2>/dev/null || echo "No tickets or bd not configured"
}

cmd_logs() {
    if [[ ! -f "$LOG_FILE" ]]; then
        log_error "No log file found at $LOG_FILE"
        exit 1
    fi

    log_info "Following Ralph logs (Ctrl+C to stop)..."
    tail -f "$LOG_FILE"
}

cmd_sessions() {
    local session_dir="$STATE_DIR/sessions"
    if [[ ! -d "$session_dir" ]]; then
        log_error "No sessions directory found"
        exit 1
    fi

    echo "=== Recent Sessions ==="
    ls -lt "$session_dir"/*.log 2>/dev/null | head -10 || echo "No sessions recorded yet"
}

cmd_help() {
    cat <<EOF
Ralph Control - Management Interface

Usage: ./ralph-control.sh <command>

Commands:
  start     Start Ralph in background
  stop      Graceful shutdown (waits for current iteration)
  kill      Force terminate Ralph immediately
  status    Show current status and goals
  logs      Stream live logs
  sessions  List recent session archives
  help      Show this help message

Examples:
  ./ralph-control.sh start    # Start autonomous development
  ./ralph-control.sh status   # Check progress
  ./ralph-control.sh stop     # Graceful shutdown
EOF
}

# Main
case "${1:-help}" in
    start)    cmd_start ;;
    stop)     cmd_stop ;;
    kill)     cmd_kill ;;
    status)   cmd_status ;;
    logs)     cmd_logs ;;
    sessions) cmd_sessions ;;
    help|--help|-h) cmd_help ;;
    *)
        log_error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
