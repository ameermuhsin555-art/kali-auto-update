# Troubleshooting Guide

## Common Issues and Solutions

### Timer/Service Issues

#### Timer not running
**Symptoms:** Updates aren't happening at scheduled time

**Solution:**
```bash
# Check timer status
sudo systemctl status kali-auto-update.timer

# Enable timer if not enabled
sudo systemctl enable kali-auto-update.timer

# Start timer
sudo systemctl start kali-auto-update.timer

# Verify it's running
sudo systemctl is-active kali-auto-update.timer
```

#### Service fails immediately
**Symptoms:** Service shows as failed in status

**Solution:**
```bash
# Check service logs
sudo journalctl -u kali-auto-update.service -n 50

# Try running script manually
sudo /usr/local/bin/kali-auto-update.sh

# Check script permissions
ls -la /usr/local/bin/kali-auto-update.sh
# Should show: -rwxr-xr-x (755)

# Fix permissions if needed
sudo chmod 755 /usr/local/bin/kali-auto-update.sh
```

#### Another instance already running
**Symptoms:** Error: "Another instance is already running"

**Solution:**
```bash
# Find the process
ps aux | grep kali-auto-update

# Kill stuck process (if truly stuck)
sudo kill -9 <PID>

# Remove lock file
sudo rm -f /var/run/kali-auto-update.lock

# Restart service
sudo systemctl restart kali-auto-update.service
```

### Permission Issues

#### Permission denied when running script
**Symptoms:** "Permission denied" error

**Solution:**
```bash
# Check current permissions
ls -la /usr/local/bin/kali-auto-update.sh

# Fix permissions
sudo chmod 755 /usr/local/bin/kali-auto-update.sh

# Verify ownership
sudo chown root:root /usr/local/bin/kali-auto-update.sh
```

#### Cannot read log file
**Symptoms:** "Permission denied" when reading logs

**Solution:**
```bash
# View with sudo
sudo tail -f /var/log/kali-auto-update.log

# Change log permissions
sudo chmod 644 /var/log/kali-auto-update.log

# Change log ownership
sudo chown root:root /var/log/kali-auto-update.log
```

### Update Issues

#### apt-get errors during update
**Symptoms:** Updates fail with apt errors

**Solution:**
```bash
# Try manual update to see errors
sudo apt-get update

# If dependencies are broken:
sudo apt --fix-broken install

# If packages are held:
sudo apt-mark unhold <package-name>

# Check apt lock
ls /var/lib/apt/lists/lock
sudo lsof /var/lib/apt/lists/lock
# Kill the process if stuck: sudo kill -9 <PID>

# Run update manually
sudo apt-get update
sudo apt-get upgrade -y
```

#### Unmet dependencies error
**Symptoms:** "Unmet dependencies" in logs

**Solution:**
```bash
# Try to fix broken installs
sudo apt --fix-broken install

# Or try dist-upgrade
sudo apt-get dist-upgrade -y

# Check for held packages
apt-mark showhold

# Unhold if needed
sudo apt-mark unhold <package>
```

#### dpkg locked error
**Symptoms:** "Could not get lock /var/lib/apt/lists/lock"

**Solution:**
```bash
# Check if apt is running
ps aux | grep apt

# Wait a few minutes, or force unlock (if no apt running):
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock

# Reconfigure dpkg
sudo dpkg --configure -a

# Try update again
sudo apt-get update
```

### Logging Issues

#### No log file created
**Symptoms:** Log file doesn't exist at /var/log/kali-auto-update.log

**Solution:**
```bash
# Create log directory
sudo mkdir -p /var/log

# Create log file
sudo touch /var/log/kali-auto-update.log

# Set permissions
sudo chmod 644 /var/log/kali-auto-update.log

# Run script manually to generate logs
sudo /usr/local/bin/kali-auto-update.sh
```

#### Logs not being written
**Symptoms:** Log file exists but is empty

**Solution:**
```bash
# Check file permissions
ls -la /var/log/kali-auto-update.log

# Check disk space
df -h /var/log

# Check inode usage
df -i /var/log

# If disk full, clean up:
sudo journalctl --vacuum=500M
sudo apt-get clean
sudo apt-get autoclean
```

#### Logs too large
**Symptoms:** Log file growing very large

**Solution:**
```bash
# Check current size
du -h /var/log/kali-auto-update.log

# Archive and compress old logs
sudo gzip /var/log/kali-auto-update.log
sudo touch /var/log/kali-auto-update.log

# Or rotate logs
sudo logrotate -f /etc/logrotate.d/kali-auto-update

# Or clear logs entirely
sudo > /var/log/kali-auto-update.log
```

### Scheduling Issues

#### Updates running at wrong time
**Symptoms:** Updates not running at scheduled time

**Solution:**
```bash
# Check current schedule
sudo systemctl list-timers kali-auto-update.timer

# View timer configuration
sudo cat /etc/systemd/system/kali-auto-update.timer

# Check system time
date
timedatectl

# Edit timer schedule
sudo nano /etc/systemd/system/kali-auto-update.timer

# Reload systemd
sudo systemctl daemon-reload

# Restart timer
sudo systemctl restart kali-auto-update.timer
```

#### Timer fires but service doesn't run
**Symptoms:** Timer activates but service doesn't execute

**Solution:**
```bash
# Check service file
sudo cat /etc/systemd/system/kali-auto-update.service

# Verify script path in service file
grep ExecStart /etc/systemd/system/kali-auto-update.service

# Test script directly
sudo /usr/local/bin/kali-auto-update.sh

# Check for errors in logs
sudo journalctl -u kali-auto-update.service -n 50
```

### Reboot Issues

#### System won't reboot after updates
**Symptoms:** AUTO_REBOOT=true but system doesn't reboot

**Solution:**
```bash
# Check if reboot is actually needed
cat /var/run/reboot-required

# Check shutdown command in logs
sudo grep "shutdown" /var/log/kali-auto-update.log

# Check if shutdown is blocked
sudo shutdown -c  # Cancel any pending shutdown

# Test reboot manually (don't actually do this in production):
# sudo shutdown -r +5 "testing reboot"
# sudo shutdown -c  # Cancel
```

### Network Issues

#### Updates fail due to network issues
**Symptoms:** "Unable to locate package" or network timeouts

**Solution:**
```bash
# Check internet connectivity
ping -c 5 8.8.8.8

# Check DNS resolution
nslookup archive.kali.org

# Update apt sources
sudo apt-get update

# Check which repos are being used
cat /etc/apt/sources.list
ls -la /etc/apt/sources.list.d/

# Try different mirror
# Edit: sudo nano /etc/apt/sources.list
# Change the mirror URL
```

#### Slow package downloads
**Symptoms:** Updates taking very long

**Solution:**
```bash
# Check available mirrors
apt-cache policy

# Use faster mirror (edit sources)
sudo nano /etc/apt/sources.list

# Examples of different mirrors:
# http://archive.kali.org/kali
# http://kali.download/kali
# http://mirrors.kernel.org/kali

# Test mirror speed
curl -w "@curl-format.txt" -o /dev/null -s https://archive.kali.org/
```

## Diagnostic Commands

Run these to gather information about your system:

```bash
# Full system info
echo "=== System Info ==="
uname -a
cat /etc/os-release

echo -e "\n=== Service Status ==="
sudo systemctl status kali-auto-update.timer
sudo systemctl status kali-auto-update.service

echo -e "\n=== Timer Schedule ==="
sudo systemctl list-timers kali-auto-update.timer

echo -e "\n=== Recent Logs ==="
sudo journalctl -u kali-auto-update.service -n 20

echo -e "\n=== Log File ==="
ls -la /var/log/kali-auto-update.log
sudo tail -50 /var/log/kali-auto-update.log

echo -e "\n=== Disk Space ==="
df -h /var/log
df -h /

echo -e "\n=== APT Issues ==="
sudo apt-get check
```

## Getting Help

If you still can't resolve the issue:

1. **Collect diagnostic information:**
```bash
sudo bash << 'EOF'
echo "=== System Diagnostics ==="
date
uname -a
systemctl status kali-auto-update.timer
systemctl status kali-auto-update.service
journalctl -u kali-auto-update.service -n 100
tail -50 /var/log/kali-auto-update.log
EOF
```

2. **Create an issue on GitHub** with:
   - The error message/symptom
   - Output from diagnostic commands above
   - Your system version (kali-release)
   - Kali Linux version
   - When the issue started

3. **Check existing issues** for similar problems:
   - https://github.com/ameermuhsin555-art/kali-auto-update/issues

## Prevention Tips

1. **Regular monitoring:**
```bash
# Check timer weekly
sudo systemctl status kali-auto-update.timer

# Review logs monthly
sudo tail -100 /var/log/kali-auto-update.log
```

2. **Keep backups:**
```bash
# Backup configs
sudo cp /etc/systemd/system/kali-auto-update.* ~/backup/
```

3. **Test before enabling auto-reboot:**
```bash
# Test updates manually first
sudo /usr/local/bin/kali-auto-update.sh

# Review logs
sudo tail -f /var/log/kali-auto-update.log
```

4. **Monitor disk space:**
```bash
# Check regularly
df -h /
df -h /var/log

# Clean old logs if needed
sudo journalctl --vacuum=1G
```
