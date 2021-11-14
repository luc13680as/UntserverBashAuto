#!/bin/bash

###############################################################
#                                                             #
# Name: UntserverBashAuto config file                         #
# Description: Contain all variables to allow scripts to work #
# Version: 1.1                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

configfile="$HOME/script/servers.csv"
scriptdir="$HOME/script/"

#Load the file in RAM to limit reads
configcontent=$(cat $scriptdir/servers.csv | tail -n +2)

#Save basic information about servers and hosts
  #The list of servers
serverslist=$(echo "$configcontent" | cut -d, -f1)

  #The list of hosts with and without the domain
hostslist=$(echo "$configcontent" | cut -d, -f2 | uniq)
hostnamelist=$(echo "$hostslist" | cut -d. -f1)

  #Numbers of hosts
hostcount=$(echo "$hostslist" | wc -l)

#Create a new array with servers per hosts
declare -A hostservers
for number in $(seq 1 $(echo "$hostcount"))
do
	#hostservers=( ["$(echo "$hostslist" | cut -d'.' -f1 | head -n "$hostcount" | tail -1)"]="$(echo "$configcontent" | grep "$(echo "$hostnamelist" | head -n "$hostcount" | tail -1)" | cut -d, -f1 | tr -s '\n' ' ' | sed 's/ *$//')" )
    hostservers["$(echo "$hostslist" | cut -d'.' -f1 | head -n "$number" | tail -1)"]="$(echo "$configcontent" | grep "$(echo "$hostnamelist" | head -n "$number" | tail -1)" | cut -d, -f1 | tr -s '\n' ' ' | sed 's/ *$//')"
done
