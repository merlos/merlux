#!/bin/bash
# install_reboot_notification.sh - Install a boot notification systemd service.
#
# Usage:
#   sudo ./sbin/install_reboot_notification.sh [--force]
#
# The installer requires the Telegram command installed by
# sbin/install_telegram.sh. It installs a root-owned notifier at
# /usr/local/sbin/reboot_notification.sh and enables a one-shot systemd service
# that sends a Telegram message after the network is online on every boot.
#
# By default, existing files are left untouched and installation stops with an
# error. Use --force to replace the installed notifier and service unit.

set -euo pipefail

SERVICE_NAME="reboot-notification.service"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
NOTIFIER_FILE="/usr/local/sbin/reboot_notification.sh"
TELEGRAM="/usr/local/bin/telegram"
SOURCE_NOTIFIER="$(dirname "$(readlink -f "$0")")/../bin/reboot_notification.sh"
FORCE=0

usage() {
    printf 'Usage: %s [--force]\n' "$(basename "$0")"
}

for argument in "$@"; do
    case "$argument" in
        --force)
            FORCE=1
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'Error: unknown argument: %s\n' "$argument" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ "$(id -u)" -ne 0 ]; then
    printf 'Error: this script must be run as root.\n' >&2
    exit 1
fi

if [ ! -x "$TELEGRAM" ]; then
    printf 'Error: %s is not executable. Run sbin/install_telegram.sh first.\n' "$TELEGRAM" >&2
    exit 1
fi

if [ "$FORCE" -eq 0 ] && { [ -e "$SERVICE_FILE" ] || [ -e "$NOTIFIER_FILE" ]; }; then
    printf 'Error: an installed reboot notification file already exists. Use --force to overwrite it.\n' >&2
    exit 1
fi

install -d -m 0755 /usr/local/sbin
install -m 0755 -o root -g root "$SOURCE_NOTIFIER" "$NOTIFIER_FILE"

cat > "$SERVICE_FILE" <<SERVICE
[Unit]
Description=Send Telegram notification after reboot
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=${NOTIFIER_FILE}

[Install]
WantedBy=multi-user.target
SERVICE

chmod 0644 "$SERVICE_FILE"
chown root:root "$SERVICE_FILE"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

printf 'Installed and enabled %s.\n' "$SERVICE_NAME"
printf 'It will send a notification on the next boot.\n'
printf 'Test manually with: systemctl start %s\n' "$SERVICE_NAME"
