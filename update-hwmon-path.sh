#!/bin/bash
# Refresh the hwmon index in /etc/fancontrol after boot-time enumeration changes.
set -euo pipefail

CONFIG=${1:-/etc/fancontrol}
CHIP_NAME=${2:-nct6776}

matches=()
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
configured=$(sed -n "s/^DEVNAME=\([^=[:space:]]*\)=$CHIP_NAME$/\1/p" "$CONFIG")

if [[ -z "$configured" ]]; then
    echo "Could not find $CHIP_NAME in DEVNAME inside $CONFIG" >&2
    exit 1
fi

if [[ "$configured" == "$current" ]]; then
    exit 0
fi

sed -i "s/\\<$configured\\>/$current/g" "$CONFIG"
echo "Updated $CONFIG from $configured to $current"
