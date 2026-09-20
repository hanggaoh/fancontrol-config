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
modprobe nct6775 || true
if ! grep -q "^nct6775" /etc/modules 2>/dev/null; then
    echo "nct6775" >> /etc/modules
fi

echo "=== Copying fancontrol configuration ==="
cp "$SCRIPT_DIR/fancontrol.conf" /etc/fancontrol
chmod 644 /etc/fancontrol

echo "=== Enabling and starting fancontrol service ==="
systemctl unmask fancontrol || true
systemctl enable fancontrol
systemctl restart fancontrol

echo "=== Verifying status ==="
systemctl status fancontrol --no-pager

echo ""
echo "Installation complete! Current sensor readings:"
sensors | grep -E "fan|temp|RPM|°C" || true
