#!/bin/bash
ORG_TOKEN=<orgToken>
expectedVersion="4.0.0" # admin should update the expectedVersion value to the latest version available
INTERVAL=600000
SCREEN_RECORD=off
LOCAL_SERVER=on
HIDE_ZLURI_TRAY_ICON=false 


CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
HOMEDIR=$(/usr/bin/dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)
echo "$ORG_TOKEN"
echo "$CURRENT_USER"
echo "$HOMEDIR"
echo "$LOCAL_SERVER"

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

# version comparison logic
function version_compare { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }
shouldUpdate=0 # whehter update required flag
finalResult=0


# perform version comparison
function perf_comparison {
   installedVersion=$(defaults read /Applications/zluri.app/Contents/Info.plist CFBundleShortVersionString) # ask installed version of the app from system
   echo "installed zluri app version: $installedVersion"
   installedVersionComparison=$(version_compare $installedVersion)
   expectedVersionComparison=$(version_compare $expectedVersion)
   if [ "$installedVersionComparison" -lt "$expectedVersionComparison" ]; then
       echo "1"
       shouldUpdate=1
   elif [ "$installedVersionComparison" -gt "$expectedVersionComparison" ] || [ "$installedVersionComparison" -eq "$expectedVersionComparison" ]; then
       echo "0"
       shouldUpdate=0
   fi
}


ZLURI_APP="/Applications/zluri.app"
if [ -e $ZLURI_APP ] # if app exsits
 then
    echo "zluri app found in /Applications/ dir"
   finalResult=0
   perf_comparison
   echo "shouldUpdate again $shouldUpdate"
 else
   echo "zluri app NOT found in /Applications/ dir"
   finalResult=1
fi


if [[ $shouldUpdate -eq 1 ]] || [[ $finalResult -eq 1 ]]
 then
 echo "it should update or exit with code 1"
 # first kill the app if running
 # needed for auto-update
 ZLURI_PROCESS=$(ps aux | grep -v grep | grep -ci zluri) # are there any processes named zluri running
 OSQUERY_PROCESS=$(ps aux | grep -v grep | grep -ci osquery) # are there any process named osquery running
 if [[ $ZLURI_PROCESS -gt 0 ]] && [[ $OSQUERY_PROCESS -gt 0 ]]
   then
   echo "trying to kill the process" # if process running
     pkill -x "zluri" # kill zluri
     pkill -x "osquery" # kill osquery
 fi
 exit 1 # will run installer in both update found and app not found
fi


if [[ $finalResult -eq 0 ]] || [[ $shouldUpdate -eq 0 ]]
   then
   echo "all ok"
   echo "writing / updating zluri generic-MDM config file"
   if [ ! -d /tmp/zluritemp ]; then
     mkdir -p /tmp/zluritemp
   else
     echo "zluritemp dir exists"
   fi
   echo "$CONFIG_JSON" > /tmp/zluritemp/client-config.json
   echo "====written the client config json file required configurations in temp directory===="
   ZLURIDIR="$HOMEDIR/Library/Application Support/zluri"
   if [ -d "$ZLURIDIR" ]; then
   echo "$CONFIG_JSON" > "$ZLURIDIR"/client-config.json
   echo "===writing config json file to appData directory==="
   else
     echo "zluri folder doesn't exist, cannot write config json file"
   fi
   exit 0
fi