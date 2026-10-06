# Kali Linux Auto Update

Automated package update scripts for Kali Linux with scheduling, logging, and systemd integration.

## Features

- Automatic package updates using `apt-get update` and `apt-get upgrade`
- Daily scheduled execution via `systemd` timer
- Logging to `/var/log/kali-auto-update.log`
- Reboot warning support when required
- Simple installation and uninstall scripts

## Prerequisites

- Kali Linux or Debian-based system
- Root or sudo access
- `systemd` installed and active

## Installation

```bash
git clone https://github.com/ameermuhsin555-art/kali-auto-update.git
cd kali-auto-update
sudo bash install.sh
```

## Manual Execution

```bash
sudo /usr/local/bin/kali-auto-update.sh
```

## Logs

```bash
sudo tail -f /var/log/kali-auto-update.log
```

## Timer Status

```bash
systemctl status kali-auto-update.timer
systemctl list-timers kali-auto-update.timer
```

## Uninstall

```bash
sudo bash uninstall.sh
```

## Notes

- The system checks for `reboot-required` and logs the status.
- The timer runs at 2:00 AM by default.
- You can change the schedule in `/etc/systemd/system/kali-auto-update.timer`.
