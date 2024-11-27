#!/bin/bash

EXTENSION_ID="zluribrowseragent@zluri.com"
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
HOMEDIR=$(/usr/bin/dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)

# Path to Firefox profiles#
PROFILE_PATH=$HOMEDIR/Library/Application\ Support/Firefox/Profiles/
echo "Started running the script $PROFILE_PATH" 
#Loop through each profile
for profile in "$PROFILE_PATH"*; do
  if [ -d "$profile" ]; then
  
    # Path for extension folder
    EXTENSIONS_DIR="$profile/extensions/"
   echo "$EXTENSIONS_DIR"
    # Check if the extension exists and remove it
    if [ -f "$EXTENSIONS_DIR/$EXTENSION_ID.xpi" ]; then
        echo "Removing extension xpi from $profile"
        rm "$EXTENSIONS_DIR/$EXTENSION_ID.xpi"
    else
        echo "Extension xpi not found in $profile"
    fi

    # Check if the extension exists fro manifest files
    if [ -f "$EXTENSIONS_DIR/$EXTENSION_ID.json" ]; then
        echo "Removing manifest file in $profile"
        rm "$EXTENSIONS_DIR/$EXTENSION_ID.json"
    else
        echo "Extension json not found in $profile"
    fi
  fi
done

echo 0