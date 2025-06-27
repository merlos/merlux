#!/bin/bash

# report_ip.sh - A script to report the current public IP address via Telegram
# Usage: 
#   /path/to/report_ip.sh
#  
# However this script is intended to be run periodically, 
# such as via cron. 
# Example of cron hourly execution:
#    crontab -e
# Add this line:  
#    0 * * * * /path/to/report_ip.sh


# Ensure:
#  1. the script is executable
#     chmod +x /path/to/report_ip.sh
# 2. the 'telegram' command is available in your PATH

# Configuration
TEMP_FILE="/tmp/current_ip.txt"
HOSTNAME=$(hostname)

# Get the current public IP
CURRENT_IP=$(curl -s http://ipinfo.io/ip)

# Check if the IP has changed
if [ -f "$TEMP_FILE" ]; then
    SAVED_IP=$(cat "$TEMP_FILE")
else
    SAVED_IP=""
fi

if [ "$CURRENT_IP" != "$SAVED_IP" ]; then
    # Save the new IP to the temporary file
    echo "$CURRENT_IP" > "$TEMP_FILE"
    
    # Report the new IP via Telegram
    logger "${HOSTNAME}: My new IP is ${CURRENT_IP}"
    telegram "${HOSTNAME}: My new IP is ${CURRENT_IP}"
fi
