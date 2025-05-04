#!/bin/bash

# Configuration variables overwritten by etc/check_vpn_status.conf
OPENVPN_NAME="openvpn"
WIREGUARD_INTERFACE="wireguard"
OPENVPN_PID_FILE="/var/run/openvpn/$OPENVPN_NAME.pid"

source ../etc/check_vpn_status.conf



if [[ -f $OPENVPN_PID_FILE ]] 
then 
  echo "OpenVPN is up" 
  exit 0
fi

# If OPENVPN is down, maybe we have wireguard launched


# Retrieve IP address for the specified interface using ip command
ip_address=$(ip addr show $WIREGUARD_INTERFACE | awk '/inet / {print $2}' | cut -d'/' -f1)

# Replace the last segment of the IP address with '1'
gateway_ip=$(echo "$ip_address" | awk -F'.' -v OFS='.' '{$NF=1; print}')

echo "Wireguard interface $WIREGUARD_INTERFACE: IP: $ip_address, gateway: $gateway_ip"

if ip link show $WIREGUARD_INTERFACE &> /dev/null; then
#    ./telegram.sh "[$0] $WIREGUARD_INTERFACE is UP ($ip_address)"
    echo "$WIREGUARD_INTERFACE is UP"
 else
    echo "$WIREGUARD_INTERFACE is DOWN"
    ./telegram.sh "[$0] OpenVPN is down ($OPENVPN_NAME)"
    ./telegram.sh "[$0] Wireguard is down ($WIREGUARD_INTERFACE)"