#!/bin/bash

# Config file should have this format:
BOT_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
CHAT_ID="XXXXXXX"

source ../etc/telegram.conf

# Arguments passed by Motion
FILE_PATH="$1"        # Full path to the saved file
EVENT_NUMBER="$2"     # Event number
CAMERA_ID="$3"        # Camera ID

echo "motion_notify: $1 - $2 - $3"

# Message to send with the file
MESSAGE="Motion event detected. 
Camera ID: $CAMERA_ID
Event Number: $EVENT_NUMBER"

# Send the file to Telegram
curl -sS -F chat_id="$CHAT_ID" \
     -F caption="$MESSAGE" \
     -F document=@"$FILE_PATH" \
     "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" > /dev/null