#!/bin/bash

###############################################################
#                                                             #
# Name: Retriever                                             #
# Description: Retrieve logs file from servers                #
# Version: 1.0                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

#Gathering data
source "$HOME"/script/servers.sh

scriptdir="${0%/*}"
logsdir=$scriptdir/collected

#Verifying if everything is here
[[ -d $logsdir ]] || mkdir -p "$logsdir"

echo -e "Launching the retrieve process"

#Store each node's subprocess pid
declare -A nodepidstop

for hostname in $hostslist
do
	scp -rpv "untserver@${hostname}:/home/untserver/serverfiles/Logs/Server_*_Prev.log $logsdir/" &
	nodepidstop["hostnametrunc"]=$!
done

wait "${nodepidstop[@]}"

echo -e "Files received !"

exit 0
