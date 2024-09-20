#!/bin/bash
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
HOMEDIR=$(/usr/bin/dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)
ORG_TOKEN= <OrgToken>
INTERVAL=600000
SCREEN_RECORD=off
echo "$ORG_TOKEN"
echo "$CURRENT_USER"
echo "$HOMEDIR"


# Deleting App components from Application folder
echo "Deleting zluri Logs"
logsPath=$HOMEDIR/Library/Logs/zluri
if [ -d "$logsPath" ]
then
rm -rf $HOMEDIR/Library/Logs/zluri
echo "***Deleted Zluri Logs Successfully***"
fi


echo "Deleting Zluri Application Support"
applicationSupportPath=$HOMEDIR/Library/Application\ Support/zluri
if [ -d "$applicationSupportPath" ]
then
rm -rf $HOMEDIR/Library/Application\ Support/zluri
echo "***Deleted Zluri Application Support Successfully***"
fi


echo "Finished:preflight"


echo "writing zluri generic-MDM config file"


if [ ! -d /tmp/zluritemp ]; then
   mkdir -p /tmp/zluritemp
else
   echo "zluritemp dir exists"
fi
echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"on\"}" > /tmp/zluritemp/client-config.json
echo "====written the client config json file required configurations in temp directory===="


# Handle the rosetta-related issues in preinstall script
# Determine the processor brand
processor_brand=$(/usr/sbin/sysctl -n machdep.cpu.brand_string)


# Determine the processor brand
if [[ "$processor_brand" == *"Apple"* ]]; then
   /bin/echo "Apple Processor is present..."


   # Check if the Rosetta service is running
   check_rosetta_status=$(/usr/bin/pgrep oahd)


   # Rosetta Folder location
   # Condition to check to see if the Rosetta folder exists. This check was added
   # because the Rosetta2 service is already running in macOS versions 11.5 and
   # greater without Rosseta2 actually being installed.
   rosetta_folder="/Library/Apple/usr/share/rosetta"


   if [[ -n $check_rosetta_status ]] && [[ -e $rosetta_folder ]]; then
       /bin/echo "Rosetta2 is installed... no action needed"
   else
       # Installs Rosetta
       /bin/echo "Rosetta is not installed... installing now"
       /usr/sbin/softwareupdate --install-rosetta --agree-to-license
   fi


elsex
   /bin/echo "Apple Processor is not present...Rosetta2 is not needed"
fi


sudo mkdir -p $HOMEDIR/Library/Application\ Support/zluri


echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"on\"}" > $HOMEDIR/Library/Application\ Support/zluri/client-config.json
echo "====written the client config json file required configurations in temp directory===="


exit 0