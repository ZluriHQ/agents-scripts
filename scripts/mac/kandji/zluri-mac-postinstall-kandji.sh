#!/bin/bash
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
HOMEDIR=$(/usr/bin/dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)
ORG_TOKEN=<orgToken>
INTERVAL=3000
SCREEN_RECORD=off
LOCAL_SERVER=on


# change ownership of zluri agent to current user, as MDM deploys and isntalls the app under root
sudo chown -R ${CURRENT_USER}:wheel /Applications/zluri.app


echo "ORG TOKEN: $ORG_TOKEN"
echo "API INTERVAL: $INTERVAL"
echo "SCREEN RECORD: $SCREEN_RECORD"
echo "CURRENT USER: $CURRENT_USER"
echo "HOMEDIR: $HOMEDIR"
echo "LOCAL_SERVER: $LOCAL_SERVER"


sleep 100 # wait for 1 min


ZLURIDIR="$HOMEDIR/Library/Application Support/zluri"


echo "ZLURIDIR: $ZLURIDIR"


if [ -d "$ZLURIDIR" ]; then
   echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"on\", \"local_server\": \"$LOCAL_SERVER\"}" > "$ZLURIDIR"/client-config.json
   echo "===writing config json file to appData directory==="
   else
     echo "zluri folder doesn't exist, cannot write config json file"
fi
