#!/bin/bash

# Configuration variables
LOG_FILE="/var/log/ping.log"
PING_DOMAIN="google.es"
PING_PACKET_COUNT=50  # Number of packets to send

# Function to perform the ping test
perform_ping_test() {
    local datetime="$(date +'%Y-%m-%d %H:%M:%S')"
    local ping_output=$(ping -c "$PING_PACKET_COUNT" "$PING_DOMAIN")
 
    # Extracting relevant information from ping output
    local packets_transmitted=$(echo "$ping_output" | grep -oP "\d+ packets transmitted" | grep -oP "\d+")
    local packets_received=$(echo "$ping_output" | grep -oP "\d+ received" | grep -oP "\d+")
    local failed_pings=$((packets_transmitted - packets_received))
    local average_ping=$(echo "$ping_output" | grep -oP "rtt min/avg/max/mdev = \K[\d.]+")
    local min_ping=$(echo "$ping_output" | grep -oP "rtt min/avg/max/mdev = [\d.]+/\K[\d.]+")
    local max_ping=$(echo "$ping_output" | grep -oP "rtt min/avg/max/mdev = [\d.]+/[\d.]+/\K[\d.]+")
    local mdev=$(echo "$ping_output" | grep -oP "rtt min/avg/max/mdev = [\d.]+/[\d.]+/[\d.]+/\K[\d.]+")
    # Log the results in CSV format
    echo "$datetime,$average_ping,$max_ping,$min_ping,$mdev,$failed_pings,$packets_transmitted,$packets_received" >> "$LOG_FILE"
					    
    # Log summary using logger
    logger -t PING_TEST "Ping test results for $PING_DOMAIN - Average: $average_ping ms, Max: $max_ping ms, Min: $min_ping ms, Mean Dev: $mdev ms, Failed: $failed_pings packets, Packets Transmitted: $packets_transmitted, Received: $packets_received"
}
						    
# Check if log file exists and add header if not
if [ ! -f "$LOG_FILE" ]; then
    echo "datetime,average ping,max ping,min ping,mean deviation,failed pings,packets transmitted, packets received" > "$LOG_FILE"
fi

# Perform the ping test
perform_ping_test
