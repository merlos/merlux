#!/bin/bash
set -eu -o pipefail

# Source the config file with absolute path to prevent directory traversal
CONFIG_FILE="$(dirname "$(readlink -f "$0")")/../etc/telegram.conf"

# Exit if config file doesn't exist or isn't readable
if [ ! -r "$CONFIG_FILE" ]; then
    echo "Error: Cannot read configuration file" >&2
    exit 1
fi

# Source configuration (contains BOT_TOKEN and CHAT_ID)
source "$CONFIG_FILE"

# Validate that we have the required variables
if [ -z "${BOT_TOKEN:-}" ] || [ -z "${CHAT_ID:-}" ]; then
    echo "Error: Missing required configuration" >&2
    exit 1
fi

# Ensure there's a message parameter
if [ $# -ne 1 ]; then
    echo "Usage: $0 <message>" >&2
    exit 1
fi

# Store the message and sanitize/escape it
MESSAGE="$1"

# Use the API to send the message, with proper quoting for all variables
curl -s -X POST \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${MESSAGE}" \
    >> /dev/null

exit $?