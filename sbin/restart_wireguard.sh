#!/bin/sh
#
# Restarts wireguard in case it is not able to contact the
# wireguard server IP
# 
#

#
# Config
#

# Ip of the wireguard server
IP="192.168.0.1" 

# Interface name
INTERFACE="wg0"

# temporary status files
NOT_RESTARTED_FILE=/tmp/wireguard-not-restarted
RESTARTED_FILE=/tmp/wireguard-restarted

# get the script directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# load the configuration file from ../etc/wireguard.conf
if [ -f "$SCRIPT_DIR/../etc/wireguard.conf" ]; then
    source "$SCRIPT_DIR/../etc/wireguard.conf"
else
    logger "Configuration file not found: $SCRIPT_DIR/../etc/wireguard.conf"
    exit 1
fi

#
# MAIN SCRIPT
#

#logger "[$0] Starting..."

ping -c 5 $IP > /tmp/restart-wireguard-log 2>&1 
if [ $? -eq 1 ]
then 
   logger "[$0] Restarting wireguard..." 
   /usr/bin/wg-quick down $INTERFACE >> /tmp/restart-wireguard-log 2>&1
   #sleep 15
   /usr/bin/wg-quick up $INTERFACE >> /tmp/restart-wireguard-log 2>&1
   
   # Check if interface is actually up
   /usr/sbin/ifconfig $INTERFACE >> /tmp/restart-wireguard-log 2>&1
   /usr/sbin/ifconfig $INTERFACE
   if [ $? -eq 1 ]
   then
      if [ -f $NOT_RESTARTED_FILE]
      then
        logger "[$0] Restart $INTERFACE FAILED. Not sending message"
      else 
        # Report not actually back
        touch $NOT_RESTARTED_FILE
        rm -f -- $RESTARTED_FILE
        telegram "[$0] Restart $INTERFACE FAILED. Will retry."
        logger "[$0] Restart $INTERFACE FAILED. Telegram message sent"
      fi
      #logger "[$0] Sad ending"
      exit 0 # exit if not up
   fi
   
   # If interface is upcheck if RESTARTED exists
   if [ -f $RESTARTED_FILE ]
      then 
        logger "[$0] Restart $INTERFACE successful. Not sent message."
      else
        # file does not exist
        touch $RESTARTED_FILE
        rm -f -- $NOT_RESTARTED_FILE
	    logger "[$0] Restarted wireguard ($INTERFACE $IP/24)"
      telegram "[$0] Restarted wireguard ($INTERFACE $IP/24)"
      fi
   #logger "[$0] Happy ending"
   exit 0
fi
# OpenVPN is working
logger "[$0] Wireguard is working on $INTERFACE ($IP)" #>> /tmp/ping
# Deletes the tmp file. -f option to avoid error message in case it does not exist
rm -f -- $RESTARTED_FILE
rm -f -- $NOT_RESTARTED_FILE
#logger "[$0] Normal ending"
exit 0