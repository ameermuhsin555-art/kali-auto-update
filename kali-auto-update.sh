#!/bin/bash

set -e

LOG_FILE="/var/log/kali-auto-update.log"
LOCK_FILE="/var/run/kali-auto-update.lock"
AUTO_REBOOT=false
REBOOT_DELAY=5

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    case "$level" in
        ERROR) echo -e "${RED}[$timestamp] [$level] $message${NC}" ;;
        SUCCESS) echo -e "${GREEN}[$timestamp] [$level] $message${NC}" ;;
        WARNING) echo -e "${YELLOW}[$timestamp] [$level] $message${NC}" ;;
        *) echo "[$timestamp] [$level] $message" ;;
    esac
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root." >&2
        exit 1
    fi
}

check_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid
        pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && ps -p "$pid" >/dev/null 2>&1; then
            log ERROR "Another update process is already running (PID: $pid)"
            exit 1
        fi
        rm -f "$LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
}

cleanup() {
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
}

update_lists() {
    log INFO "Updating package lists"
    if apt-get update >> "$LOG_FILE" 2>&1; then
        log SUCCESS "Package lists updated successfully"
        return 0
    fi
    log ERROR "Failed to update package lists"
    return 1
}

upgrade_packages() {
    log INFO "Starting upgrade"
    if DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::="--force-confold" >> "$LOG_FILE" 2>&1; then
        log SUCCESS "Upgrade completed successfully"
        return 0
    fi
    log ERROR "Upgrade failed"
    return 1
}

remove_unused() {
    log INFO "Removing unused packages"
    if apt-get autoremove -y >> "$LOG_FILE" 2>&1; then
        log SUCCESS "Unused packages removed"
        return 0
    fi
    log WARNING "Autoremove failed; continuing"
    return 0
}

clean_cache() {
    log INFO "Cleaning package cache"
    if apt-get autoclean -y >> "$LOG_FILE" 2>&1; then
        log SUCCESS "Package cache cleaned"
        return 0
    fi
    log WARNING "Autoclean failed; continuing"
    return 0
}

check_reboot_needed() {
    if [[ -f /var/run/reboot-required ]]; then
        log WARNING "System reboot required"
        return 0
    fi
    log INFO "No reboot required"
    return 1
}

reboot_system() {
    if [[ "$AUTO_REBOOT" == true ]]; then
        log INFO "Scheduling reboot in $REBOOT_DELAY minutes"
        shutdown -r +"$REBOOT_DELAY" "Automatic reboot after Kali updates"
    else
        log WARNING "Reboot required, but AUTO_REBOOT is disabled"
    fi
}

main() {
    log INFO "=== Kali Linux automatic update started ==="
    check_root
    init_log
    check_lock

    local success=true

    update_lists || success=false
    upgrade_packages || success=false
    remove_unused || success=false
    clean_cache || success=false

    if [[ "$success" == true ]]; then
        log SUCCESS "=== Update process completed successfully ==="
        if check_reboot_needed; then
            reboot_system
        fi
        exit 0
    fi

    log ERROR "=== Update process completed with errors ==="
    exit 1
}

main "$@"
