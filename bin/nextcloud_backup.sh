#!/bin/bash

# nextcloud_backup.sh - Weekly backup script for Nextcloud
# Created: $(date +"%Y-%m-%d")

# Default config location
CONFIG_FILE="$HOME/etc/nextcloud_backup.conf"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -c, --config CONFIG_FILE    Specify config file (default: $CONFIG_FILE)"
    echo "  -h, --help                  Display this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Check permissions on config file
CONFIG_PERMS=$(stat -c "%a" "$CONFIG_FILE")
if [ "$CONFIG_PERMS" != "600" ]; then
    echo "Warning: Config file permissions are not secure ($CONFIG_PERMS). Fixing..."
    chmod 600 "$CONFIG_FILE"
fi

# Source the config file
source "$CONFIG_FILE"

# Set default values if not defined in config
: "${TELEGRAM_SCRIPT:="/usr/local/bin/telegram"}"
: "${SOURCE_DIR:="$HOME/nextcloud"}"
: "${BACKUP_DIR:="$HOME/backup/nextcloud"}"
: "${LOG_DIR:="$HOME/backup/logs"}"
: "${MOUNT_POINT1:="/mnt/secure"}"
: "${MOUNT_POINT2:="/mnt/nextcloud"}"
: "${LOG_RETENTION:=10}"
: "${ENABLE_NOTIFICATIONS:=true}"
: "${RSYNC_EXTRA_OPTIONS:=""}"

# Create timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/nextcloud_backup_$TIMESTAMP.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Ensure logs have proper permissions (readable only by the user)
chmod 700 "$LOG_DIR"

# Start logging
echo "Starting Nextcloud backup at $(date)" > "$LOG_FILE"
echo "Using config file: $CONFIG_FILE" >> "$LOG_FILE"
chmod 600 "$LOG_FILE"  # Set permissions for log file (user only)

# Function to send notification via Telegram
send_telegram_notification() {
    local message="$1"
    if [ "$ENABLE_NOTIFICATIONS" = true ] && [ -x "$TELEGRAM_SCRIPT" ]; then
        "$TELEGRAM_SCRIPT" "$message"
    elif [ "$ENABLE_NOTIFICATIONS" = true ]; then
        echo "Warning: Telegram script not found or not executable: $TELEGRAM_SCRIPT" >> "$LOG_FILE"
    fi
}

# Function to check if a filesystem is mounted
check_mount() {
    if mountpoint -q "$1"; then
        return 0  # Mounted
    else
        return 1  # Not mounted
    fi
}

# Validate mount points
echo "Validating mount points..." >> "$LOG_FILE"
MOUNT_ERROR=0

if ! check_mount "$MOUNT_POINT1"; then
    echo "ERROR: $MOUNT_POINT1 is not mounted!" >> "$LOG_FILE"
    MOUNT_ERROR=1
fi

if ! check_mount "$MOUNT_POINT2"; then
    echo "ERROR: $MOUNT_POINT2 is not mounted!" >> "$LOG_FILE"
    MOUNT_ERROR=1
fi

if [ $MOUNT_ERROR -eq 1 ]; then
    ERROR_MSG="Nextcloud backup FAILED: Required mount points are not available."
    echo "$ERROR_MSG" >> "$LOG_FILE"
    send_telegram_notification "$ERROR_MSG"
    exit 1
fi

echo "All required mount points are available." >> "$LOG_FILE"

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Created backup directory: $BACKUP_DIR" >> "$LOG_FILE"
fi

# Start time for calculating duration
START_TIME=$(date +%s)

# Perform the backup using rsync with statistics
echo "Starting rsync process at $(date)" >> "$LOG_FILE"

# Use rsync with stats to capture detailed information
RSYNC_CMD="rsync -avz --delete --stats $RSYNC_EXTRA_OPTIONS"
echo "Running command: $RSYNC_CMD" >> "$LOG_FILE"

RSYNC_OUTPUT=$(eval $RSYNC_CMD \
    "\"$SOURCE_DIR/\"" \
    "\"$BACKUP_DIR/\"" 2>&1)

RSYNC_STATUS=$?

# Save rsync output to log
echo "$RSYNC_OUTPUT" >> "$LOG_FILE"

# Parse rsync statistics
NUM_FILES=$(echo "$RSYNC_OUTPUT" | grep "Number of files transferred" | awk '{print $5}')
TOTAL_FILES=$(echo "$RSYNC_OUTPUT" | grep "Number of regular files transferred" | awk '{print $6}')
TOTAL_SIZE=$(echo "$RSYNC_OUTPUT" | grep "Total transferred file size" | awk '{print $5,$6}')
TOTAL_SIZE_BYTES=$(echo "$RSYNC_OUTPUT" | grep "Total transferred file size" | awk '{print $5}')

# Convert bytes to MB for easier reading
TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE_BYTES / 1048576" | bc)

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_MIN=$((DURATION / 60))
DURATION_SEC=$((DURATION % 60))

# Check if the backup was successful
if [ $RSYNC_STATUS -eq 0 ]; then
    SUCCESS_MSG="Nextcloud backup completed successfully."
    STATS_MSG="Stats: Files transferred: $NUM_FILES, Total files: $TOTAL_FILES, Size: ${TOTAL_SIZE_MB}MB, Duration: ${DURATION_MIN}m ${DURATION_SEC}s"
    
    echo "$SUCCESS_MSG" >> "$LOG_FILE"
    echo "$STATS_MSG" >> "$LOG_FILE"
    
    # Send success notification
    send_telegram_notification "$SUCCESS_MSG $STATS_MSG"
else
    FAILED_MSG="Nextcloud backup FAILED with status $RSYNC_STATUS"
    echo "$FAILED_MSG" >> "$LOG_FILE"
    send_telegram_notification "$FAILED_MSG"
    exit 1
fi

# Keep only the most recent N log files
find "$LOG_DIR" -type f -name "nextcloud_backup_*.log" | \
    sort -r | \
    tail -n +$((LOG_RETENTION + 1)) | \
    xargs rm -f 2>/dev/null

exit 0