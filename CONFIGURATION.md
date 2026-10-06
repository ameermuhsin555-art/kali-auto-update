# Configuration Guide

This guide explains how to configure the Kali Auto Update system for your needs.

## Timer Schedule

The default schedule is **2 AM daily**. To change this:

1. Edit the timer file:
```bash
sudo nano /etc/systemd/system/kali-auto-update.timer
```

2. Modify the `OnCalendar` line in the `[Timer]` section

3. Reload and restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart kali-auto-update.timer
```

### OnCalendar Examples

| Schedule | OnCalendar Value |
|----------|------------------|
| Daily at 2 AM | `*-*-* 02:00:00` |
| Daily at midnight | `daily` or `*-*-* 00:00:00` |
| Every 6 hours | `*-*-* 00,06,12,18:00:00` |
| Every Monday at 3 AM | `Mon *-*-* 03:00:00` |
| Every day at 1:30 AM | `*-*-* 01:30:00` |
| Every 4 hours | `0/4:00:00` |
| Twice daily (2 AM & 2 PM) | `*-*-* 02,14:00:00` |

**Note:** Times use 24-hour format

## Auto-Reboot Configuration

To enable automatic system reboot after updates:

1. Edit the update script:
```bash
sudo nano /usr/local/bin/kali-auto-update.sh
```

2. Find the configuration section near the top:
```bash
AUTO_REBOOT=false
REBOOT_DELAY=5
```

3. Change to:
```bash
AUTO_REBOOT=true
REBOOT_DELAY=5  # Minutes before reboot
```

4. Save the file

The system will now automatically reboot X minutes after updates complete.

## Advanced Logging Configuration

### Log Rotation

To prevent logs from growing too large, set up log rotation:

1. Create a logrotate configuration:
```bash
sudo nano /etc/logrotate.d/kali-auto-update
```

2. Add the following:
```
/var/log/kali-auto-update.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
```

3. Test the configuration:
```bash
sudo logrotate -d /etc/logrotate.d/kali-auto-update
```

### View Verbose Logs

View all update operations:
```bash
sudo journalctl -u kali-auto-update.service -n 100
```

Follow logs in real-time:
```bash
sudo journalctl -u kali-auto-update.service -f
```

View logs since last boot:
```bash
sudo journalctl -u kali-auto-update.service -b
```

## Conditional Updates

### Only Update at Low System Load

Create a wrapper script at `/usr/local/bin/kali-auto-update-conditional.sh`:

```bash
#!/bin/bash

# Only run if system load is below 2.0
LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }')
LOAD_INT=${LOAD%.*}

if [ $LOAD_INT -lt 2 ]; then
    /usr/local/bin/kali-auto-update.sh
else
    echo "System load too high ($LOAD). Skipping update."
fi
```

Then modify the service file to use this wrapper:
```bash
sudo sed -i 's|ExecStart=.*|ExecStart=/usr/local/bin/kali-auto-update-conditional.sh|' /etc/systemd/system/kali-auto-update.service
sudo systemctl daemon-reload
```

### Quiet Hours (No Updates During Business Hours)

Create a wrapper that respects quiet hours:

```bash
#!/bin/bash

# Don't update between 8 AM and 6 PM on weekdays
HOUR=$(date +%H)
DAY=$(date +%u)  # 1=Monday, 5=Friday

if [ $DAY -le 5 ] && [ $HOUR -ge 8 ] && [ $HOUR -lt 18 ]; then
    echo "Quiet hours - skipping update"
    exit 0
fi

/usr/local/bin/kali-auto-update.sh
```

## Monitoring and Notifications

### Check If Updates Are Running

```bash
ps aux | grep kali-auto-update
```

### Get Update History

```bash
sudo journalctl -u kali-auto-update.service --since "1 week ago" | less
```

### Count Updates in Last 30 Days

```bash
sudo journalctl -u kali-auto-update.service --since "30 days ago" | grep "started" | wc -l
```

### Email Notifications on Failure

Create `/usr/local/bin/kali-auto-update-notify.sh`:

```bash
#!/bin/bash

OUTPUT=$(/usr/local/bin/kali-auto-update.sh 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "Kali Auto Update failed on $(hostname)" | \
    mail -s "Update Failed: $(hostname)" admin@example.com
    echo "$OUTPUT" | mail -s "Update Failed: $(hostname)" admin@example.com
fi

exit $EXIT_CODE
```

Modify service to use the notify wrapper:
```bash
sudo sed -i 's|ExecStart=.*|ExecStart=/usr/local/bin/kali-auto-update-notify.sh|' /etc/systemd/system/kali-auto-update.service
```

## Performance Tuning

### Reduce I/O Impact

Edit `/etc/systemd/system/kali-auto-update.service` and add to `[Service]` section:

```ini
IOSchedulingClass=idle
IOSchedulingPriority=7
CPUSchedulingPolicy=idle
```

This makes the update process use idle I/O and CPU scheduling.

### Limit Bandwidth (if on metered connection)

Create a wrapper with rate limiting:

```bash
#!/bin/bash
apt-get -o Acquire::http::Dl-Limit=500 update
apt-get -o Acquire::http::Dl-Limit=500 upgrade -y
```

## Troubleshooting Configuration

### Timer won't start
```bash
sudo systemctl start kali-auto-update.timer
sudo systemctl status kali-auto-update.timer
```

### Service stuck or hanging
```bash
# View what the service is doing
sudo journalctl -u kali-auto-update.service -f

# Force stop if needed
sudo systemctl kill -s KILL kali-auto-update.service
```

### Permissions issues
```bash
# Reset permissions
sudo chmod 755 /usr/local/bin/kali-auto-update.sh
sudo chmod 644 /etc/systemd/system/kali-auto-update.*
```

## Uninstall Configuration

To return to default configuration or start fresh:

```bash
sudo bash uninstall.sh
```

This will remove all modifications while preserving logs.
