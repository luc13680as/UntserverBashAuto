#!/bin/bash

###############################################################
#                                                             #
# Name: BanHammer                                             #
# Description: Automatically ban someone on every server      #
# Version: 1.0                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

source "$HOME"/script/servers.sh

#Get args and usage
if [[ $# -eq 0 ]]
then
	echo "[ERROR] Usage: $0 [SteamID] [Reason] [Period in days]"
	exit 1
elif [[ $# -eq 1 ]]
then
	steamid=$1
	reason="No reason have been provided"
	duration="Permanent"
elif [[ $# -eq 2 ]]
then
	steamid=$1
	reason=$2
	duration="Permanent"
elif [[ $# -eq 3 ]]
then
	steamid=$1
	reason=$2
	duration=$3
fi

#Check if the SteamID is correct
if [[ ! $steamid =~ ^7656[0-9]{13}$ ]]
then
	echo "[ERROR] SteamID64 provided is not valid !"
	exit 1
fi

#Check if the reason is a string
if [[ ! $reason =~ [a-zA-Z] ]]
then
	echo "[ERROR] The reason provided is not a string !"
	exit 1
fi

#Check if the duration is a number and convert the given time in seconds
if [[ ! $duration =~ ^[0-9]{1,}$ ]]
then
	echo "[ERROR] Duration entered is not a number !"
	exit 1
else
    if [ ! $duration -ge 1 ] || [ ! $duration -le 365 ]
	then
		echo "[ERROR] Time entered is incorrect. Please use a duration between 1 and 365 days"
		exit 1
	fi
	durationSecs=$((duration*86400))
fi

echo "Player to ban: $steamid"
echo "Reason: $reason"
echo "Duration: $duration days or $durationSecs seconds"

#Browsing node list
#for hostname in $hostslist
#do
#    #Browsing servers for each node
#    for server in ${hostservers["$(echo "$hostname" | cut -d. -f1)"]}
#    do
#        ssh untserver@"${hostname}" "tmux send-keys -t "$server":0 Space Enter; tmux send-keys -t "$server":0 'ban $steamid' Enter"
#    done
#done
