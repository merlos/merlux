#!/bin/sh

# HTTP Port 80 Management Script
# Usage: ./script.sh {open|close} [interface]

# Function to display usage
usage() {
    echo "Usage: $0 {open|close|status} [interface]"
    echo "  status  - Check if port 80 is open"
    echo "  open    - Open port 80"
    echo "  close   - Close port 80"
    echo "  interface - Optional interface name (overrides default from config)"
    exit 1
}

# Check if at least one parameter is provided
if [ $# -lt 1 ]; then
    usage
fi

ACTION="$1"
INTERFACE_OVERRIDE="$2"

# Check if action is valid
if [ "$ACTION" != "open" ] && [ "$ACTION" != "close" ] && [ "$ACTION" != "status" ]; then
    echo "Error: Invalid action '$ACTION'. Use 'open', 'close', or 'status'"
    usage
fi

# Configuration file path (relative the script location)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../etc/http.conf"


# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE does not exist"
    exit 1
fi

# Source the configuration file to load DEFAULT_INTERFACE
source "$CONFIG_FILE"

# Use override interface if provided, otherwise use default from config
if [ -n "$INTERFACE_OVERRIDE" ]; then
    INTERFACE="$INTERFACE_OVERRIDE"
else
    INTERFACE="$DEFAULT_INTERFACE"
fi

# Check if interface is set
if [ -z "$INTERFACE" ]; then
    echo "Error: No interface specified and DEFAULT_INTERFACE not found in $CONFIG_FILE"
    exit 1
fi

# Check if the interface exists
if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
    echo "Error: Interface '$INTERFACE' does not exist"
    exit 1
fi

# Function to open port 80
open_port() {
    echo "Opening port 80 on interface $INTERFACE..."
    
    # Check if rule already exists
    if iptables -C INPUT -i "$INTERFACE" -p tcp --dport 80 -j ACCEPT 2>/dev/null; then
        echo "Port 80 is already open on interface $INTERFACE"
        return 0
    fi
    
    # Insert rule at the beginning of INPUT chain
    if iptables -I INPUT 1 -i "$INTERFACE" -p tcp --dport 80 -j ACCEPT; then
        echo "Successfully opened port 80 on interface $INTERFACE"
    else
        echo "Error: Failed to open port 80 on interface $INTERFACE"
        exit 1
    fi
}

# Function to close port 80
close_port() {
    echo "Closing port 80 on interface $INTERFACE..."
    
    # Remove the rule if it exists
    if iptables -C INPUT -i "$INTERFACE" -p tcp --dport 80 -j ACCEPT 2>/dev/null; then
        if iptables -D INPUT -i "$INTERFACE" -p tcp --dport 80 -j ACCEPT; then
            echo "Successfully closed port 80 on interface $INTERFACE"
        else
            echo "Error: Failed to close port 80 on interface $INTERFACE"
            exit 1
        fi
    else
        echo "Port 80 is already closed on interface $INTERFACE"
    fi
}

# Check if running as root (required for iptables)
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Execute the appropriate action
case "$ACTION" in
    open)
        open_port
        ;;
    close)
        close_port
        ;;
    status)
        check_status
        exit $?
        ;;
esac

echo "Current iptables rules for port 80:"
iptables -L INPUT -n --line-numbers | grep -E "(Chain INPUT|dpt:80|^[0-9]+.*tcp.*:80)"
exit 0