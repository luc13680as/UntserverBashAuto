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



#cd ./serverfiles/Logs/
#find Server_pastanetwork1_Prev.log
