#!/bin/bash
# writing config json file to appData directory
# CURRENT_USER=$(/bin/ls -l /dev/console | awk '{print $3}')
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
HOMEDIR=$(/usr/bin/dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)
ORG_TOKEN=605072ae40973f002d004cc5
INTERVAL=600000
SCREEN_RECORD=off


echo "ORG TOKEN: $ORG_TOKEN"
echo "API INTERVAL: $INTERVAL"
echo "SCREEN RECORD: $SCREEN_RECORD"
echo "CURRENT USER: $CURRENT_USER"
echo "HOMEDIR: $HOMEDIR"


sleep 300


ZLURIDIR="$HOMEDIR/Library/Application Support/zluri"


echo "ZLURIDIR: $ZLURIDIR"
# cd $ZLURIDIR


if [ -d "$ZLURIDIR" ]; then
   echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"on\"}" > "$ZLURIDIR"/client-config.json
   echo "===writing config json file to appData directory==="
   else
     echo "zluri folder doesn't exist, cannot write config json file"
fi
