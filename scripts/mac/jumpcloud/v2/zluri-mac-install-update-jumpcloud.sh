#!/bin/bash

# Supported Versions: 3.3.0 and above 

#Config
ORG_TOKEN="<ORG_TOKEN>"     # Replace <ORG_TOKEN> with organization token
INTERVAL=600000             
SCREEN_RECORD=off           # Turn this on if you want to see the option to enable screen record
SILENT_AUTH=on              # Turn this off if agent should up if authentication is not successful
LOCAL_SERVER=on             # This is required when browser agent can authenticate with loggedin info from desktop agents
EXPECTED_VERSION="3.6.3"    # Replace with the latest version
ZLURI_PKG_URL="https://zluri-prod-agent-builds.s3.us-west-2.amazonaws.com/zluri-3.6.3.pkg"

################################################## DO NOT MAKE ANY MODIFICATION BELOW ##################################################

#Paths
ZLURI_APP="/Applications/zluri.app"                 # Path of the Zluri app
ZLURI_DIR="$HOME/Library/Application Support/zluri" # Path to contents of the Zluri app
CONFIG_FILE="$ZLURI_DIR/client-config.json"         # Path to add client-config file
TMP_CONFIG_DIR="/tmp/zluritemp"                     # Path for tmp config
TMP_CONFIG_FILE="/tmp/zluritemp/client-config.json" # Path to add client-config file in tmp
TMP_ZLURI_FILE="/tmp/zluri-agent.pkg"               # Temp path to add client-config file
LOG_FILE="/tmp/mdm_script_log.txt"                  # Temp log file

#Other variables
shouldUpdate=0;

# Log everything to a file
# exec > "$LOG_FILE" 2>&1

# Function to get the currently logged-in user
get_logged_in_user() {
    /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
}

# Function to get compare versions string
version_compare() {
    printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' ')
}

# Function to perform version comparison and check if an update is needed
perf_comparison() {
    installedVersion=$(defaults read /Applications/zluri.app/Contents/Info.plist CFBundleShortVersionString)

    installedVersionComparison=$(version_compare $installedVersion)
    echo "$installedVersionComparison installed version"

    expectedVersionComparison=$(version_compare $EXPECTED_VERSION)
    echo "$expectedVersionComparison expected version"

    if [ "$installedVersionComparison" -lt "$expectedVersionComparison" ]; then
        echo "should update"
        shouldUpdate=1;  # update required
    else
        echo "update not required"
        shouldUpdate=0;  # no update needed
    fi
}

# Get the current user
current_user=$(get_logged_in_user)
if [ -z "$current_user" ]; then
    echo "No user is currently logged in."
    exit 1
fi
echo "Current logged-in user: $current_user"
HOMEDIR=$(/usr/bin/dscl . -read /Users/"$current_user" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)


# Function to download and install Zluri agent
download_install_agent(){
    echo "DEBUG: Downloading"
    curl -o "$TMP_ZLURI_FILE" "$ZLURI_PKG_URL"
    echo "DEBUG: Zluri appDownloaded"
    sudo chown -R "$current_user":staff "$TMP_ZLURI_FILE"
    echo "DEBUG: Permission granted for tmp file"
    /usr/sbin/installer -pkg "$TMP_ZLURI_FILE" -target /Applications
    echo "DEBUG: Zluri app installed"
    sudo chown -R "$current_user":staff /Applications/zluri.app
    echo "DEBUG: Owning successful the zluri.app"
}

# Check if zluri app exists and compare versions
if [ -e "$ZLURI_APP" ]; then
   echo "zluri app found in /Applications/"
   echo "$shouldUpdate before perf_comparision"
   perf_comparison
   echo "$shouldUpdate after perf_comparision"
   if [ $shouldUpdate -eq 1 ]; then
       echo "Update needed, updating zluri app..."
       # If update is needed, remove old version and install the new one
       echo "killing and removing existing zluri app..."
       pkill -f "zluri"
       pkill -x "osquery"
       rm -rf "$ZLURI_APP"
       echo "Download new zluri app..."
       download_install_agent
   else
       echo "No update needed."
   fi
else
   echo "zluri app not found, installing..."
   download_install_agent
   echo "DEBUG: Exited function"
fi

# Create the necessary directories and write the config file
if [ ! -d "$TMP_CONFIG_DIR" ]; then
    mkdir -p $TMP_CONFIG_DIR
fi

# Write the config file to the tmp dir
echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"$SILENT_AUTH\", \"local_server\": \"$LOCAL_SERVER\"}" > "$TMP_CONFIG_FILE"
echo "Written config file to "$TMP_CONFIG_FILE""

# Ensure the correct user permissions on zluri.app
sudo chown -R "$current_user":staff /Applications/zluri.app

# Check if zluri and osquery are running, and start if not
ZLURI_PROCESS=$(pgrep -f zluri | wc -l)
echo "ZLURI_PROCESS count: $ZLURI_PROCESS"

OSQUERY_PROCESS=$(pgrep -f osquery | wc -l)
echo "OSQUERY_PROCESS count: $OSQUERY_PROCESS"


if [[ $ZLURI_PROCESS -eq 0 ]] && [[ $OSQUERY_PROCESS -eq 0 ]]; then
   echo "zluri app not running, attempting to start it..."
   su -l "$current_user" -c 'open /Applications/zluri.app'
   if [ $? -ne 0 ]; then
       echo "Failed to open zluri.app, checking logs for more details..."
       log show --predicate 'eventMessage contains "zluri.app"' --info --last 30m
       exit 1
   fi
else
   echo "zluri is already running."
fi


# Remove the temp file pkg from users machine
rm -rf "$TMP_ZLURI_FILE"

#Wait for 100seconds for the zluri app to install 
echo "sleep start"
echo "$(date)"
sleep 100
echo "$(date)"
echo "sleep end"

if [ -d "$HOMEDIR/Library/Application Support/zluri" ]; then
# Write the config file to the user's Application Support dir
echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"$SILENT_AUTH\", \"local_server\": \"$LOCAL_SERVER\"}" > "$HOMEDIR/Library/Application Support/zluri/client-config.json"
echo "Written config file to $HOMEDIR/Library/Application Support/zluri/client-config.json"
else echo "Zluri folder doesn't exist yet"
fi

# End
echo "All tasks completed successfully."
exit 0
