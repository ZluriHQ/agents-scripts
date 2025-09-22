#!/bin/bash

# Get current user and home directory
CURRENT_USER=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }')
HOMEDIR=$(/usr/bin/dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)

# Configuration variables
ORG_TOKEN=<orgToken> # needs to be added by the customer
INTERVAL=600000 # check enrollment API in ms
SCREEN_RECORD=off # screen recording permission
LOCAL_SERVER=on # node auth server, cross auth of DA & BA, as per the customer pref
HIDE_ZLURI_TRAY_ICON=true # Setting this flag will not show the zluri icon on the status bar above

# Validate required inputs
if [ -z "$CURRENT_USER" ]; then
    echo "Error: Could not determine current user"
    exit 1
fi

# Create config JSON
CONFIG_JSON=$(cat << EOF 
{
  "org_token": "$ORG_TOKEN",
  "interval": "$INTERVAL",
  "screen_recording": "$SCREEN_RECORD",
  "silent_auth": "on",
  "local_server": "$LOCAL_SERVER",
  "hide_zluri_tray_icon": $HIDE_ZLURI_TRAY_ICON
}
EOF
)

echo "Current user: $CURRENT_USER"
echo "Home directory: $HOMEDIR"
echo "Local server: $LOCAL_SERVER"

# Create temp directory if it doesn't exist
if [ ! -d /tmp/zluritemp ]; then
   mkdir -p /tmp/zluritemp
fi

# Write config file to temp directory
echo "$CONFIG_JSON" > /tmp/zluritemp/client-config.json
echo "Written config to temp directory"

# Create application support directory and write config
mkdir -p "$HOMEDIR/Library/Application Support/zluri"
echo "$CONFIG_JSON" > "$HOMEDIR/Library/Application Support/zluri/client-config.json"
echo "Written config to application directory"

# Kill existing zluri process
if pgrep -x zluri > /dev/null; then
    echo "Stopping zluri process"
    pkill -x zluri
    sleep 5
fi

# Start zluri application
echo "Starting zluri application"
open /Applications/zluri.app

echo "Configuration completed"
exit 0