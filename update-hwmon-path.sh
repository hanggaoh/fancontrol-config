#!/bin/bash
# Refresh the hwmon index in /etc/fancontrol after boot-time enumeration changes.
set -euo pipefail

CONFIG=${1:-/etc/fancontrol}
CHIP_NAME=${2:-nct6776}

matches=()
shopt -s nullglob
for name_file in /sys/class/hwmon/hwmon*/name; do
    if [[ $(<"$name_file") == "$CHIP_NAME" ]]; then
        matches+=("$(basename "$(dirname "$name_file")")")
    fi
done

if (( ${#matches[@]} != 1 )); then
    echo "Expected exactly one $CHIP_NAME hwmon device; found ${#matches[@]}" >&2
    exit 1
fi

current=${matches[0]}
device=/sys/class/hwmon/$current
expected_path=$(sed -n 's/^DEVPATH=[^=[:space:]]*=\([^[:space:]]*\)$/\1/p' "$CONFIG")
actual_path=$(readlink -f "$device/device")
if [[ -z "$expected_path" || "$actual_path" != "/sys/$expected_path" ]]; then
    echo "Sensor physical path does not match $CONFIG; refusing to control a different device" >&2
    exit 1
fi
for attribute in pwm1 pwm1_enable pwm2 pwm2_enable pwm3 pwm3_enable fan1_input fan2_input fan3_input temp2_input; do
    if [[ ! -r "$device/$attribute" ]]; then
        echo "Required sensor attribute missing: $device/$attribute" >&2
        exit 1
    fi
done
configured=$(sed -n "s/^DEVNAME=\([^=[:space:]]*\)=$CHIP_NAME$/\1/p" "$CONFIG")

if [[ ! "$configured" =~ ^hwmon[0-9]+$ ]]; then
    echo "Could not find $CHIP_NAME in DEVNAME inside $CONFIG" >&2
    exit 1
fi

if [[ "$configured" == "$current" ]]; then
    exit 0
fi

sed -i "s/\\<$configured\\>/$current/g" "$CONFIG"
echo "Updated $CONFIG from $configured to $current"
