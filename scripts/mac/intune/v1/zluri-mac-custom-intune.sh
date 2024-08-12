#!/bin/bash
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
HOMEDIR=$(/usr/bin/dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)
ORG_TOKEN=<ENTER YOUR ORG TOKEN HERE PLEASE!!!!>
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

echo "====will attemp to update the contents of config json file===="
echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"on\", \"local_server\": \"$LOCAL_SERVER\"}" > "$ZLURIDIR"/client-config.json


processor_brand=$(/usr/sbin/sysctl -n machdep.cpu.brand_string)


if [[ "$processor_brand" == *"Apple"* ]]; then
    /bin/echo "Apple Processor is present..."
    check_rosetta_status=$(/usr/bin/pgrep oahd)
    rosetta_folder="/Library/Apple/usr/share/rosetta"

    if [[ -n $check_rosetta_status ]] && [[ -e $rosetta_folder ]]; then
        /bin/echo "Rosetta2 is installed... no action needed"
    else

        /bin/echo "Rosetta is not installed... installing now"
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi
else
    /bin/echo "Apple Processor is not present...Rosetta2 is not needed"
fi

sleep 300

ZLURIDIR="$HOMEDIR/Library/Application Support/zluri"

echo "ZLURIDIR: $ZLURIDIR"

if [ -d "$ZLURIDIR" ]; then
    echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"on\", \"local_server\": \"$LOCAL_SERVER\"}" > "$ZLURIDIR"/client-config.json
    echo "===writing config json file to appData directory==="
    else
      echo "zluri folder doesn't exist, cannot write config json file"
fi

function version_compare { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }

function perf_comparison {
installedVersion=$(defaults read /Applications/zluri.app/Contents/Info.plist CFBundleShortVersionString)
echo "installed zluri app version: $installedVersion"
expectedVersion="3.3.0"
[ $(version_compare $installedVersion) -lt $(version_compare $expectedVersion) ] && echo "1"
[[ $(version_compare $installedVersion) -gt $(version_compare $expectedVersion) || $(version_compare $installedVersion) -eq $(version_compare $expectedVersion) ]] && echo "0"
}

shouldUpdate="0"
finalResult="0"

ZLURI_APP="/Applications/zluri.app"
if [ -e $ZLURI_APP ]
  then
     echo "zluri app found in /Applications/ dir"
    finalResult="0"
    perf_comparison
    shouldUpdate=$?
    echo "shouldUpdate again $shouldUpdate"
fi

if [[ $shouldUpdate -eq "1" ]]
  then
  echo "it should update or exit with code 1"

  ZLURI_PROCESS=$(ps aux | grep -v grep | grep -ci zluri)
  OSQUERY_PROCESS=$(ps aux | grep -v grep | grep -ci osquery)
  if [[ $ZLURI_PROCESS -gt 0 ]] && [[ $OSQUERY_PROCESS -gt 0 ]]
    then
    echo "trying to kill the process"
      pkill -x "zluri"
      pkill -x "osquery"
  fi

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
      sudo rm -rf /Applications/zluri.app
fi