#!/bin/bash
#
# report_off.sh — Monitor a host by IP and send Telegram notifications on state changes.
#
# Usage:
#   report_off.sh <ip_address>
#
# Description:
#   Pings the given IP address and tracks whether it is up or down using a
#   state file in ../var/. Designed to be run from a cron job.
#
#   - When a host transitions from UP to DOWN, a Telegram message is sent.
#   - When a host transitions from DOWN back to UP, a Telegram message is sent.
#   - Repeated cron runs while the host remains in the same state send no message.
#
# Dependencies:
#   - telegram (see telegram.sh): must be available at $TELEGRAM
#   - ping, grep, mkdir
#
# State files:
#   ../var/ping_state_<ip_with_underscores>  (e.g. ping_state_192_168_1_1)
#
# Cron example (check every 5 minutes):
#   */5 * * * * /path/to/merlux/bin/report_off.sh 192.168.1.1
#
set -eu -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TELEGRAM="/usr/local/bin/telegram"
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
