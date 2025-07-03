#!/bin/bash
ORG_TOKEN=<orgToken>   # admin should update the ORG_TOKEN found in Zluri > Sources > Desktop agents page
expectedVersion="4.0.0" # admin should update the expectedVersion value to the latest version available
INTERVAL=600000         
SCREEN_RECORD=off       # Setting this flag to on will require screen record permission. NOTE: ZLURI WILL NOT RECORD SCREEN
LOCAL_SERVER=on         # Setting this flag on will start a server which helps in cross authenticating zluri browser extension
ZluriPackageLink="https://zluri-prod-agent-builds.s3.us-west-2.amazonaws.com/zluri-4.0.0.pkg"   ## Add the expected zluri package link to install here

CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' ) 
HOMEDIR=$(/usr/bin/dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)

echo "$ORG_TOKEN"
echo "$CURRENT_USER"
echo "$HOMEDIR"
echo "$LOCAL_SERVER"

# version comparison logic
function version_compare { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }

# perform version comparison
function perf_comparison {
   installedVersion=$(defaults read /Applications/zluri.app/Contents/Info.plist CFBundleShortVersionString) # ask installed version of the app from system
   echo "installed zluri app version: $installedVersion"
   installedVersionComparison=$(version_compare $installedVersion)
   echo $installedVersionComparison
   expectedVersionComparison=$(version_compare $expectedVersion)
   echo $expectedVersionComparison
   if [ "$installedVersionComparison" -lt "$expectedVersionComparison" ]; then
       echo "installed version is lesser than expected version"
       remove_existing_agent
       install_zluri_agent
   elif [ "$installedVersionComparison" -gt "$expectedVersionComparison" ] || [ "$installedVersionComparison" -eq "$expectedVersionComparison" ]; then
       echo "Installed version is greater than or equal to expected version"
   fi
}

# write config files
function write_config() {
    echo "writing / updating zluri generic-MDM config file"
   if [ ! -d "/tmp/zluritemp" ]; then
     mkdir -p "/tmp/zluritemp"
   else
     echo ""/tmp/zluritemp" dir exists"
   fi
   echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"on\", \"local_server\": \"$LOCAL_SERVER\"}" > "/tmp/zluritemp"/client-config.json
   echo "====written the client config json file required configurations in temp directory===="
   ZLURIDIR="$HOMEDIR/Library/Application Support/zluri"
   if [ -d "$ZLURIDIR" ]; then
   echo "{\"org_token\": \"$ORG_TOKEN\", \"interval\": \"$INTERVAL\", \"screen_recording\": \"$SCREEN_RECORD\", \"silent_auth\": \"on\", \"local_server\": \"$LOCAL_SERVER\"}" > "$ZLURIDIR"/client-config.json
   echo "===writing config json file to appData directory==="
   else
     echo "zluri folder doesn't exist, cannot write config json file"
   fi
}

#Function to install zluri agent
function install_zluri_agent() {
  curl -o /tmp/zluri-agent.pkg $ZluriPackageLink
  sudo chown -R ${CURRENT_USER}:staff /tmp/zluri-agent.pkg
  /usr/sbin/installer -pkg /tmp/zluri-agent.pkg -target /Applications
  sudo chown -R ${CURRENT_USER}:staff /Applications/zluri.app
  sleep 20
  write_config
}

#Function to remove existing agent
function remove_existing_agent() {
 # first kill the app if running
 # needed for auto-update
 ZLURI_PROCESS=$(ps aux | grep -v grep | grep -ci zluri) # are there any processes named zluri running
 OSQUERY_PROCESS=$(ps aux | grep -v grep | grep -ci osquery) # are there any process named osquery running
 if [[ $ZLURI_PROCESS -gt 0 ]]
   then
   echo "trying to kill the app" # if process running
     pkill -x "zluri" # kill zluri
 fi
 if [[ $OSQUERY_PROCESS -gt 0 ]]
   then
   echo "trying to kill the process" # if process running
     pkill -x "osquery" # kill osquery
 fi
}

#Check if Zluri app is present
ZLURI_APP="/Applications/zluri.app"
write_config
if [ -e $ZLURI_APP ] # if app exsits
 then
  echo "zluri app found in /Applications/ dir will do version compare"
  perf_comparison
 else
  echo "zluri app NOT found in /Applications/ dir, will install zluri"
  install_zluri_agent
exit 0
fi