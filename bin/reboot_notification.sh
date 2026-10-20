#!/bin/bash
set -euo pipefail

TELEGRAM="/usr/local/bin/telegram"
HOSTNAME="$(hostname --fqdn 2>/dev/null || hostname)"
MAX_ATTEMPTS=6
RETRY_DELAY=10

interface_addresses() {
    ip -o addr show up 2>/dev/null \
        | awk '$2 != "lo" { sub(/\/[0-9]+$/, "", $4); print $2 "=" $4 }' \
        | sort -u
}

if ! INTERFACES=$(interface_addresses); then
    INTERFACES="unavailable"
fi

if [ -z "$INTERFACES" ]; then
    INTERFACES="none"
fi

PUBLIC_IP=$(curl --fail --silent --show-error --max-time 10 https://api.ipify.org 2>/dev/null || true)
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="unavailable"
fi

MESSAGE=$(printf 'Host %s rebooted.\n\nInterfaces and IPs:\n%s\n\nPublic IP: %s' \
    "$HOSTNAME" "$INTERFACES" "$PUBLIC_IP")

logger -t reboot-notification "Host ${HOSTNAME} rebooted; public IP: ${PUBLIC_IP}"

for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
    if "$TELEGRAM" "$MESSAGE"; then
        exit 0
    fi

    if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
        logger -t reboot-notification \
            "Telegram delivery failed (attempt ${attempt}/${MAX_ATTEMPTS}); retrying in ${RETRY_DELAY}s"
        sleep "$RETRY_DELAY"
    fi
done

logger -p daemon.err -t reboot-notification \
    "Telegram delivery failed after ${MAX_ATTEMPTS} attempts"
exit 1
