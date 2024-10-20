#!/bin/bash
#
# usage ./tv-internet.sh on|off|status
#
# Script to block or unblock D+ access to the TV
#
# Define regex patterns for the domains
PATTERNS=("dssott.com" "bamgrid.com")

# Define the Docker container name
DOCKER_CONTAINER="pihole"

# Function to execute commands inside the Docker container
execute_in_container() {
    echo docker exec -i "$DOCKER_CONTAINER" pihole "$@"
    docker exec -i "$DOCKER_CONTAINER" pihole "$@"
}

# Function to add domains to the blacklist
add_to_blacklist() {
    for pattern in "${PATTERNS[@]}"; do
        execute_in_container wildcard "$pattern"
    done
}

# Function to remove domains from the blacklist
remove_from_blacklist() {
    for pattern in "${PATTERNS[@]}"; do
        execute_in_container wildcard -d "$pattern"
    done
}

# Function to check the status of the domains
check_status() {
    #/usr/bin/sleep 1
    local status="OFF"
    local result=$(execute_in_container wildcard -l ) #| grep "$pattern")
    #echo $result
    if [[ "$result" == *"Not showing empty list"* ]]; then
        status="ON"
    fi
    echo "Internet is $status"
}

# Main logic to handle arguments
case "$1" in
    on)
        remove_from_blacklist
        ;;
    off)
        add_to_blacklist
        ;;
    status)
        check_status
        ;;
    *)
        echo "Invalid argument: $1. Use 'on', 'off', or 'status'."
        exit 1
        ;;
esac
