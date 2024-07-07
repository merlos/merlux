#!/bin/sh

#
# This file tells if in the last 
TMP_FILE=/tmp/openvpn-restarted

# IP Address of the OpenVPN server within the VPN subnet
IP="192.168.1.1" 

ping -c 2 $IP #>> /tmp/ping 
if [ $? -eq 1 ]
then 
   logger "cron-job: $0 Restarting OpenVPN" 
   /usr/bin/systemctl restart openvpn
   # check if file exists
   if [ -f $TMP_FILE ]
   then 
      echo "Already sent message OpenVPN restarted"
   else
      # file does not exist
      touch $TMP_FILE
      /bin/telegram.sh "[$0] Restarted OpenVPN (subnet $IP/24)"
   fi
   exit 0
fi
# OpenVPN is working
echo "[$0] OpenVPN working $IP" #>> /tmp/ping
# Deletes the tmp file. -f option to avoid error message in case it does not exist
rm -f -- $TMP_FILE
exit 0