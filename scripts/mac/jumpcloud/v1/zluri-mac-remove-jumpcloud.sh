#!/bin/bash
#zluri desktop agent removal script


CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
HOMEDIR=$(/usr/bin/dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)


ZLURI_PROCESS=$(ps aux | grep -v grep | grep -ci zluri)
OSQUERY_PROCESS=$(ps aux | grep -v grep | grep -ci osquery)


if [[ $ZLURI_PROCESS -gt 0 ]] && [[ $OSQUERY_PROCESS -gt 0 ]]
 then
   echo "kill the zluri processes"
   pkill -x "zluri"
   pkill -x "osquery"
fi


#remove app
ZLURI_APP="/Applications/zluri.app"
ZLURIDIR="$HOMEDIR/Library/Application Support/zluri"
LOGS_DIR="$HOMEDIR/Library/Logs/zluri"


if [ -e $ZLURI_APP ]
 then
   echo "attempt to remove zluri app"
   sudo rm -rf /Applications/zluri.app
   echo "zluri app removed"
fi


# remove app support
if [ -e $ZLURIDIR ]
 then
   sudo rm -rf "$ZLURIDIR"
fi


# remove logs
if [ -e $LOGS_DIR ]
 then
   sudo rm -rf /Applications/zluri.app
fi