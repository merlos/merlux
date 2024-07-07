#!/bin/bash

TOKEN=XXXXXX
CHAT_ID=XXXXXX
MESSAGE=$1
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$MESSAGE" > /dev/null