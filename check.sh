#!/bin/bash

# Script that continuously scans a file for certain keyword(s) and if found immediately produce warning in a Slack/Mattermost channel
# WebHooks

HOSTNAME=$(hostname)

CHAT="https://chat.domain.com/hooks/xxxxxxxxxxxxxxxxxxxxxxxxxx > /dev/null 2>&1"

ERR1="disconnected"
#ERR2="number mismatch"

LOG=/home/user/log/file.debug
SR=NameOfService

tail -n 0 -F $LOG | \
while read LINE
do

# FIRST ERROR MESSAGE (KEYWORD)

 TEST=$(echo "$LINE" | grep -q "$ERR1")
 if [ $? == 0 ]; then
	             MSG=$(echo $LINE | awk -F"$ERR1," '{print $2}')
                     EXP=$(echo $MSG |awk -F" " '{print $2}') 
                     curl -X POST --data-urlencode 'payload={"channel": "#alerts", "username": "alert_bot", "text": "'"${HOSTNAME}: ${SR} disconnected - ${ERR1}\n"'", "icon_emoji": ":ghost:", "attachments": [ {"text": "'"Somei additional text message for {SR}"'", "color": "danger"} ] }' $CHAT
                     exit 1
 fi

done

