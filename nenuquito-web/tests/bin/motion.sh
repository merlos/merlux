#!/bin/bash
#
# usage ./motion.sh on|off|status
#
# Function to check the status
# returns inactive or active
check_status() {
    echo "inactive" 
}
# Main logic to handle arguments
case "$1" in
    on)
        echo "Turning motion on"
        ;;
    off)
        echo "Turning motion off"
        ;;
    status)
        check_status
        ;;
    *)
        echo "Invalid argument: $1. Use 'on', 'off', or 'status'."
        exit 1
        ;;
esac
