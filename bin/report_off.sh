#!/bin/bash
set -eu -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TELEGRAM="$SCRIPT_DIR/telegram.sh"
STATE_DIR="$SCRIPT_DIR/../var"

# Validate argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <ip_address>" >&2
    exit 1
fi

IP="$1"

# Basic IP address validation
if ! echo "$IP" | grep -qE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$'; then
    echo "Error: Invalid IP address: $IP" >&2
    exit 1
fi

# State file path (e.g., var/ping_state_192_168_1_1)
STATE_FILE="$STATE_DIR/ping_state_$(echo "$IP" | tr '.' '_')"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Read previous state (default: up — no message on first run if host is still down)
PREV_STATE="up"
if [ -f "$STATE_FILE" ]; then
    PREV_STATE="$(cat "$STATE_FILE")"
fi

# Ping the host: 3 packets, 2-second timeout per packet
if ping -c 3 -W 2 "$IP" > /dev/null 2>&1; then
    CURRENT_STATE="up"
else
    CURRENT_STATE="down"
fi

if [ "$CURRENT_STATE" = "down" ] && [ "$PREV_STATE" = "up" ]; then
    echo "down" > "$STATE_FILE"
    "$TELEGRAM" "Host $IP is DOWN"
elif [ "$CURRENT_STATE" = "up" ] && [ "$PREV_STATE" = "down" ]; then
    echo "up" > "$STATE_FILE"
    "$TELEGRAM" "Host $IP is back UP"
else
    # No state change — update state file silently
    echo "$CURRENT_STATE" > "$STATE_FILE"
fi
