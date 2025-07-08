#!/bin/bash

# Supported Versions: 3.3.0 and above 

#Config
ORG_TOKEN="<ORG_TOKEN>"     # Replace <ORG_TOKEN> with organization token
INTERVAL=600000             
SCREEN_RECORD=off           # Turn this on if you want to see the option to enable screen record
SILENT_AUTH=on              # Turn this off if agent should up if authentication is not successful
LOCAL_SERVER=on             # This is required when browser agent can authenticate with loggedin info from desktop agents
EXPECTED_VERSION="4.0.0"    # Replace with the latest version
ZLURI_PKG_URL="https://zluri-prod-agent-builds.s3.us-west-2.amazonaws.com/zluri-4.0.0.pkg"
HIDE_ZLURI_TRAY_ICON=false # Setting this flag will not show the zluri icon on the status bar above

################################################## DO NOT MAKE ANY MODIFICATION BELOW ##################################################

CONFIG_CONTENT=$(cat <<EOF
{
  "org_token": "$ORG_TOKEN",
  "interval": "$INTERVAL",
  "screen_recording": "$SCREEN_RECORD",
  "silent_auth": "$SILENT_AUTH",
  "local_server": "$LOCAL_SERVER",
  "hide_zluri_tray_icon": $HIDE_ZLURI_TRAY_ICON
}
EOF
)

echo $CONFIG_CONTENT


#Paths
ZLURI_APP="/Applications/zluri.app"                 # Path of the Zluri app
ZLURI_DIR="${HOME}/Library/Application Support/zluri" # Path to contents of the Zluri app
CONFIG_FILE="${ZLURI_DIR}/client-config.json"         # Path to add client-config file
TMP_CONFIG_DIR="/tmp/zluritemp"                     # Path for tmp config
TMP_CONFIG_FILE="/tmp/zluritemp/client-config.json" # Path to add client-config file in tmp
TMP_ZLURI_FILE="/tmp/zluri-agent.pkg"               # Temp path to add client-config file
LOG_FILE="/tmp/mdm_script_log.txt"                  # Temp log file

#Other variables
shouldUpdate=0;

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

# Function to download and install Zluri agent
download_install_agent(){
    curl -o "$TMP_ZLURI_FILE" "$ZLURI_PKG_URL"
    sudo chown -R "$current_user":staff "$TMP_ZLURI_FILE"
    /usr/sbin/installer -pkg "$TMP_ZLURI_FILE" -target /Applications
    sudo chown -R "$current_user":staff /Applications/zluri.app
}

# Function to write config files
write_config_files() {
    # Create system-wide directory if it doesn't exist
    if [ ! -d "$ZLURI_DIR" ]; then
        mkdir -p "$ZLURI_DIR" || {
            echo "Error: Failed to create system-wide directory"
            exit 1
        }
    fi

    # Create user-specific directory if it doesn't exist
    USER_ZLURI_DIR="/Users/$current_user/Library/Application Support/zluri"
    if [ ! -d "$USER_ZLURI_DIR" ]; then
        mkdir -p "$USER_ZLURI_DIR" || {
            echo "Error: Failed to create user-specific directory"
            exit 1
        }
    fi

    # Create temporary directory if it doesn't exist
    if [ ! -d "$TMP_CONFIG_DIR" ]; then
        mkdir -p "$TMP_CONFIG_DIR" || {
            echo "Error: Failed to create temporary directory"
            exit 1
        }
    fi

    # Write to system-wide config
    echo "$CONFIG_CONTENT" > "$CONFIG_FILE" || {
        echo "Error: Failed to write system-wide config file"
        exit 1
    }

    # Write to user-specific config
    USER_CONFIG_FILE="$USER_ZLURI_DIR/client-config.json"
    echo "$CONFIG_CONTENT" > "$USER_CONFIG_FILE" || {
        echo "Error: Failed to write user-specific config file"
        exit 1
    }

    # Write to temporary config
    echo "$CONFIG_CONTENT" > "$TMP_CONFIG_FILE" || {
        echo "Error: Failed to write temporary config file"
        exit 1
    }

    # Set permissions
    sudo chown -R "$current_user":staff "$ZLURI_DIR" "$USER_ZLURI_DIR"
    chmod 755 "$ZLURI_DIR" "$USER_ZLURI_DIR"
    chmod 755 "$CONFIG_FILE" "$USER_CONFIG_FILE"

    # Verify files
    echo -e "\nVerifying config files..."
    if [ -f "$CONFIG_FILE" ]; then
        echo "System-wide config file written successfully at $CONFIG_FILE"
    else
        echo "Error: System-wide config file not found!"
        exit 1
    fi

    if [ -f "$USER_CONFIG_FILE" ]; then
        echo "User-specific config file written successfully at $USER_CONFIG_FILE"
    else
        echo "Error: User-specific config file not found!"
        exit 1
    fi
}


echo "Step 1: Writing initial configuration files..."
write_config_files

echo "Step 2: Checking for existing installation..."
# Check if zluri app exists and compare versions
if [ -e "$ZLURI_APP" ]; then
    echo "zluri app found in /Applications/"
    echo "$shouldUpdate before perf_comparision"
    perf_comparison
    echo "$shouldUpdate after perf_comparision"
    if [ $shouldUpdate -eq 1 ]; then
        echo "Update needed, updating zluri app..."
        # If update is needed, remove old version and install the new one
        echo "Attempting to kill and remove existing zluri app..."
        
        # Attempt graceful termination first
        pkill -f "zluri"
        sleep 2  # Wait for the process to terminate
        
        # Check if the process is still running
        if pgrep -f "zluri" > /dev/null; then
            echo "zluri app did not terminate gracefully. Forcing termination..."
            # Force kill all instances of the zluri app
            pkill -9 -f "zluri"
        fi

        # Verify process termination
        if pgrep -f "zluri" > /dev/null; then
            echo "Error: Unable to terminate zluri app. Please check manually."
            exit 1
        else
            echo "zluri app terminated successfully."
        fi

        # Remove the existing app
        echo "Removing existing zluri app..."
        rm -rf "$ZLURI_APP"

        echo "Downloading and installing the new zluri app..."
        download_install_agent
    else
        echo "No update needed."
    fi
else
    echo "zluri app not found, installing..."
    download_install_agent
fi


# Ensure the correct user permissions on zluri.app
sudo chown -R "$current_user":staff /Applications/zluri.app

echo "Step 3: Starting the application..."
# Check if zluri and osquery are running, and start if not
ZLURI_PROCESS=$(pgrep -f zluri | wc -l)
OSQUERY_PROCESS=$(pgrep -f osquery | wc -l)

echo "ZLURI_PROCESS count: $ZLURI_PROCESS"
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

echo "Step 4: Waiting for application to initialize (1 minute)..."
sleep 60

echo "Step 5: Writing final configuration files..."
write_config_files

echo "All tasks completed successfully."
exit 0