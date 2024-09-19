#!/bin/bash
# Log everything to a file
exec > /tmp/mdm_script_install_log_root.txt 2>&1

CURRENT_USER=$(/bin/ls -l /dev/console | awk '{print $3}')
# version comparison logic
function version_compare { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }

# perform version comparision
function perf_comparison {
    installedVersion=$(defaults read /Applications/zluri.app/Contents/Info.plist CFBundleShortVersionString) # ask installed version of the app from system
    expectedVersion="3.6.3" # admin should update the expectedVersion value to the latest version available
    installedVersionComparison=$(version_compare $installedVersion)
    expectedVersionComparison=$(version_compare $expectedVersion)

    if [ "$installedVersionComparison" -lt "$expectedVersionComparison" ]; then
        echo "1"
    elif [ "$installedVersionComparison" -gt "$expectedVersionComparison" ] || [ "$installedVersionComparison" -eq "$expectedVersionComparison" ]; then
        echo "0"
    fi
}

shouldUpdate=0
finalResult=0
ZLURI_APP="/Applications/zluri.app"
if [ -e $ZLURI_APP ]; then
   echo "zluri app found in /Applications/ dir"
   installedVersion=$(defaults read /Applications/zluri.app/Contents/Info.plist CFBundleShortVersionString)
   echo "installed zluri app version: $installedVersion"
   shouldUpdate=$(perf_comparison)
   echo "shouldUpdate value: $shouldUpdate"
 else
   echo "zluri app NOT found in /Applications/ dir"
   # exit 1
   finalResult=1
fi


if [[ $shouldUpdate -eq 1 ]] || [[ $finalResult -eq 1 ]]; then
    echo "it should update or exit with code 1"
 # first kill the app if running
 # needed for auto-update
 # ZLURI_PROCESS=$(ps aux | grep -v grep | grep -ci zluri)
 # OSQUERY_PROCESS=$(ps aux | grep -v grep | grep -ci osquery)
    ZLURI_PROCESS=$(pgrep -f zluri | wc -l)
    OSQUERY_PROCESS=$(pgrep -f osquery | wc -l)

    if [[ $ZLURI_PROCESS -gt 0 ]] && [[ $OSQUERY_PROCESS -gt 0 ]]; then
        echo "trying to kill the process"
        pkill -f "zluri"
        pkill -f "osquery"
    fi

 # remove zluri app
 echo "attempting to remove zluri app"
 rm -rf /Applications/zluri.app
 CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
 HOMEDIR=$(/usr/bin/dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)
 ORG_TOKEN=<ORG_TOKEN>
 INTERVAL=600000
 SCREEN_RECORD=off
 LOCAL_SERVER=on
 echo "$ORG_TOKEN"
 echo "$CURRENT_USER"
 echo "$HOMEDIR"
 echo "$LOCAL_SERVER"
 echo "writing zluri generic-MDM config file"


 if [ ! -d /tmp/zluritemp ]; then
    mkdir -p /tmp/zluritemp
 else
    echo "zluritemp dir exists"
 fi
 echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"on\", \"local_server\": \"$LOCAL_SERVER\"}" > /tmp/zluritemp/client-config.json
 echo "====written the client config json file required configurations in temp directory===="
  # curl and usr/bin/installer
  curl -o /tmp/zluri-agent.pkg "https://zluri-agents-intenal-s3.s3.us-west-2.amazonaws.com/zluri-3.6.3.pkg"
  sudo chown -R ${CURRENT_USER}:staff /tmp/zluri-agent.pkg
  /usr/sbin/installer -pkg /tmp/zluri-agent.pkg -target /Applications
  sudo chown -R ${CURRENT_USER}:staff /Applications/zluri.app
  sleep 200

  ZLURIDIR="$HOMEDIR/Library/Application Support/zluri"
   echo "ZLURIDIR: $ZLURIDIR"
    if [ -d "$ZLURIDIR" ]; then
        echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"on\", \"local_server\": \"$LOCAL_SERVER\"}" > "$ZLURIDIR"/client-config.json
        echo "===writing config json file to appData directory==="
    else
        echo "zluri folder doesn't exist, cannot write config json file"
    fi

fi


if [[ $finalResult -eq 0 ]] || [[ $shouldUpdate -eq 0 ]]; then
   echo "all ok"
   exit 0
fi


echo "exiting with code 1"
exit 1