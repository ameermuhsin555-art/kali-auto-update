#!/bin/bash

set -e

SERVICE_NAME="kali-auto-update"

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root." >&2
        exit 1
    fi
}

main() {
    check_root
    systemctl stop "${SERVICE_NAME}.timer" 2>/dev/null || true
    systemctl disable "${SERVICE_NAME}.timer" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
    rm -f "/etc/systemd/system/${SERVICE_NAME}.timer"
    systemctl daemon-reload
    rm -f "/usr/local/bin/kali-auto-update.sh"
    echo "Kali Auto Update has been uninstalled."
}

main "$@"
