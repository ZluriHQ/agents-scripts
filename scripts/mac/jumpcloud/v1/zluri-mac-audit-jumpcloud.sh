#!/bin/bash
CURRENT_USER=$(/bin/ls -l /dev/console | awk '{print $3}')
# version comparison logic
function version_compare { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }


# perform version comparision
function perf_comparison {
   installedVersion=$(defaults read /Applications/zluri.app/Contents/Info.plist CFBundleShortVersionString) # ask installed version of the app from system
   expectedVersion="4.0.2" # admin should update the expectedVersion value to the latest version available
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
  # curl and usr/bin/installer
  curl -o /tmp/zluri-agent.pkg "https://zluri-prod-agent-builds.s3.us-west-2.amazonaws.com/zluri-4.0.2.pkg"
  sudo chown -R ${CURRENT_USER}:staff /tmp/zluri-agent.pkg
  /usr/sbin/installer -pkg /tmp/zluri-agent.pkg -target /Applications
  sudo chown -R ${CURRENT_USER}:staff /Applications/zluri.app
fi


if [[ $finalResult -eq 0 ]] || [[ $shouldUpdate -eq 0 ]]; then
   echo "all ok"
   exit 0
fi


echo "exiting with code 1"
exit 1