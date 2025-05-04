#!/bin/bash

source ../etc/telegram.conf

MESSAGE=$1
URL="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"

curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$MESSAGE" >> /dev/null