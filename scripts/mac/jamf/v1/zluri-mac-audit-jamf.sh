#!/bin/bash
# version comparison logic
function version_compare { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }


# perform version comparision
function perf_comparison {
installedVersion=$(defaults read /Applications/zluri.app/Contents/Info.plist CFBundleShortVersionString) # ask installed version of the app from system
echo "installed zluri app version: $installedVersion"
expectedVersion="3.2.3" # admin should update the expectedVersion value to the latest version available
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
   echo "shouldUpdate $shouldUpdate"
 else
   echo "zluri app NOT found in /Applications/ dir"
   finalResult="1"
fi


if [[ $shouldUpdate -eq "1" ]] || [[ $finalResult -eq "1" ]]
 then
 echo "it should update or exit with code 1"
 # first kill the app if running
 # needed for auto-update
 ZLURI_PROCESS=$(ps aux | grep -v grep | grep -ci zluri)
 OSQUERY_PROCESS=$(ps aux | grep -v grep | grep -ci osquery)
 if [[ $ZLURI_PROCESS -gt 0 ]] && [[ $OSQUERY_PROCESS -gt 0 ]]
   then
   echo "trying to kill the process"
     pkill -x "zluri"
     pkill -x "osquery"
 fi
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
   # the -id should be whatever policy id is assigned while creating the deployment policy in jamfpro, it varies for each customer
 sudo jamf policy -id 3
fi


if [[ $finalResult -eq 0 ]] || [[ $shouldUpdate -eq 0 ]]
   then
   echo "all ok"
   exit 2
fi
