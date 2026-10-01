#!/bin/bash
# Installation script to apply this fancontrol configuration
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo or as root: sudo ./install.sh"
    exit 1
fi

echo "=== Installing dependencies ==="
apt-get update
apt-get install -y lm-sensors fancontrol

echo "=== Loading nct6775 driver ==="
modprobe nct6775
if ! grep -q "^nct6775" /etc/modules 2>/dev/null; then
    echo "nct6775" >> /etc/modules
fi

echo "=== Copying fancontrol configuration ==="
if [ -f /etc/fancontrol ]; then
    backup=$(mktemp /etc/fancontrol.backup.XXXXXX)
    cp -p /etc/fancontrol "$backup"
    echo "Existing configuration backed up to $backup"
fi
cp "$SCRIPT_DIR/fancontrol.conf" /etc/fancontrol
chmod 644 /etc/fancontrol

echo "=== Installing boot-time hwmon path refresh ==="
install -m 755 "$SCRIPT_DIR/update-hwmon-path.sh" /usr/local/sbin/update-fancontrol-hwmon
mkdir -p /etc/systemd/system/fancontrol.service.d
install -m 644 "$SCRIPT_DIR/recovery.conf" /etc/systemd/system/fancontrol.service.d/recovery.conf
install -m 644 "$SCRIPT_DIR/hwmon-path.conf" /etc/systemd/system/fancontrol.service.d/hwmon-path.conf
install -D -m 755 "$SCRIPT_DIR/fancontrol-sleep" /lib/systemd/system-sleep/fancontrol
/usr/local/sbin/update-fancontrol-hwmon
systemctl daemon-reload

echo "=== Enabling and starting fancontrol service ==="
systemctl unmask fancontrol || true
systemctl enable fancontrol
systemctl restart fancontrol

echo "=== Verifying status ==="
systemctl status fancontrol --no-pager

echo ""
echo "Installation complete! Current sensor readings:"
sensors | grep -E "fan|temp|RPM|°C" || true
