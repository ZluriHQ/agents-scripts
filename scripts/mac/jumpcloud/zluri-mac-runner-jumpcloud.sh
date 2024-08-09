#!/bin/bash
# Log everything to a file
exec > /tmp/mdm_script_log.txt 2>&1


# Print environment variables
env > /tmp/mdm_env.txt
# Function to get the currently logged-in user
get_logged_in_user() {
   /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
}


# Get the currently logged-in user
current_user=$(get_logged_in_user)
# Check if the user is found
if [ -z "$current_user" ]; then
   echo "No user is currently logged in."
   exit 1
fi


echo "Current logged-in user: $current_user"


# export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/local/bin:/opt/jc/bin


ZLURI_PROCESS=$(pgrep -f zluri | wc -l)
OSQUERY_PROCESS=$(pgrep -f osquery | wc -l)
CURRENT_USER=$(/bin/ls -l /dev/console | awk '{print $3}')
sudo -u "$CURRENT_USER" chown -R ${CURRENT_USER}:staff /Applications/zluri.app


echo "ZLURI_PROCESS count: $ZLURI_PROCESS"
echo "OSQUERY_PROCESS count: $OSQUERY_PROCESS"
echo "CURRENT_USER: $CURRENT_USER"


# zluri not running
if [[ $ZLURI_PROCESS -eq 0 ]] && [[ $OSQUERY_PROCESS -eq 0 ]]
then
   echo "app not running, will open zluri agent"
   # open -a /Applications/zluri.app # open the agent if not running
   su -l "$current_user" -c 'open /Applications/zluri.app'
   if [ $? -ne 0 ]; then
       echo "Failed to open zluri.app, checking logs for more details..."
       log show --predicate 'eventMessage contains "zluri.app"' --info --last 30m
       exit 1
   fi
else
   echo "already running"
fi
