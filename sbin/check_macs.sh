#!/bin/bash

# Set default interface and file paths
INTERFACE="eth1"
FILE_PATH="/root/merlux/etc/macs.json"

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Load configuration from the check_macs.conf file 
# usingthe script dir 
if [[ -f "$SCRIPT_DIR/../etc/check_macs.conf" ]]; then
  source "$SCRIPT_DIR/../etc/check_macs.conf"
else
  echo "Configuration file not found: $SCRIPT_DIR/../etc/check_macs.conf"
  exit 1
fi

source ../etc/check_macs.conf

# Parse command line options
while getopts "i:f:h" opt; do
  case ${opt} in
    i ) INTERFACE=$OPTARG;;
    f ) FILE_PATH=$OPTARG;;
    h ) echo "Usage: $0 [-i interface] [-f file_path]"; exit;;
    \? ) echo "Invalid option: $OPTARG" 1>&2; exit 1;;
    : ) echo "Option -$OPTARG requires an argument." 1>&2; exit 1;;
  esac
done


# Get the local IP address
LOCAL_IP=$(ip addr show dev $INTERFACE | grep "inet " | awk '{print $2}' | cut -d'/' -f1)

# Discover hosts in the local network
# --exclude this host ip (does not display a Mac)
HOSTS=$(nmap -sS $LOCAL_IP/24 -Pn --exclude $LOCAL_IP | grep "MAC Address")

#echo Hosts
#echo $HOSTS
#echo "----------"
#logger "[check-macs] Checking Macs for hosts: $HOSTS"
# Load the filter list from the file
FILTER_LIST=$(jq -r '.macFilterList[] | select(.filterMode == "pass") | .mac' $FILE_PATH)

# Loop over the discovered hosts and check if their MAC addresses are in the filter list

echo "$HOSTS" | while IFS= read -r line; do
    #echo "Extracted line: $line"
    # Mac address in lower
    MAC_ADDR=$(echo "$line" | awk '{print $3}' | tr '[:upper:]' '[:lower:]')    
    VENDOR=$(echo "$line" | awk -F '[()]' '{print $2}')

    #logger "arp2 $arp2"
    IP=$(/usr/sbin/arp -e -n | grep $MAC_ADDR | awk '{print $1}')
    DEVICE="[check-macs] Device detected: IP=$IP, MAC=$MAC_ADDR, VENDOR=$VENDOR"

    #echo $UNAUTHORIZED
    #logger "IP: $IP"
    logger $DEVICE
    if [[ "$FILTER_LIST" != *"$MAC_ADDR"* ]]; then
      # gets first 3 bytes of the address and to uppercase
      MAC3=$(echo $MAC_ADDR | awk -F: '{print $1$2$3}' | tr '[:lower:]' '[:upper:]')
      VENDOR2=$(cat /var/lib/ieee-data/oui.txt | grep $MAC3 | awk '{print $4$5$6$7$8$9$10}')
      UNAUTHORIZED="[check-macs] !!! UNAUTHORIZED device detected: IP=$IP, MAC=$MAC_ADDR, VENDOR=$VENDOR VENDOR2=$VENDOR2"
      #echo $UNAUTHORIZED
      logger $UNAUTHORIZED
      ../bin/telegram.sh "$UNAUTHORIZED"
    fi
done

