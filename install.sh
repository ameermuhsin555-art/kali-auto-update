#!/bin/bash

set -e

SCRIPT_NAME="kali-auto-update.sh"
INSTALL_PATH="/usr/local/bin"
SERVICE_NAME="kali-auto-update"
LOG_FILE="/var/log/kali-auto-update.log"

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root." >&2
        exit 1
    fi
}

check_script() {
    if [[ ! -f "$SCRIPT_NAME" ]]; then
        echo "Script not found: $SCRIPT_NAME"
        echo "Run this from the repository directory."
        exit 1
    fi
}

install_script() {
    install -m 0755 "$SCRIPT_NAME" "$INSTALL_PATH/$SCRIPT_NAME"
    echo "Installed script to $INSTALL_PATH/$SCRIPT_NAME"
}

create_service() {
    cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<'EOF'
[Unit]
Description=Kali Linux automatic update service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/kali-auto-update.sh
User=root

[Install]
WantedBy=multi-user.target
EOF

    cat > "/etc/systemd/system/${SERVICE_NAME}.timer" <<'EOF'
[Unit]
Description=Run Kali Linux auto update daily

[Timer]
OnCalendar=*-*-* 02:00:00
RandomizedDelaySec=10m
Persistent=true

[Install]
WantedBy=timers.target
EOF

    chmod 0644 "/etc/systemd/system/${SERVICE_NAME}.service" "/etc/systemd/system/${SERVICE_NAME}.timer"
    systemctl daemon-reload
}

enable_timer() {
    systemctl enable --now "${SERVICE_NAME}.timer"
    systemctl start "${SERVICE_NAME}.timer"
    echo "Enabled and started ${SERVICE_NAME}.timer"
}

setup_log() {
    mkdir -p /var/log
    touch "$LOG_FILE"
    chmod 0644 "$LOG_FILE"
}

main() {
    check_root
    check_script
    setup_log
    install_script
    create_service
    enable_timer
    echo "Installation complete."
    echo "Logs: $LOG_FILE"
}

main "$@"
