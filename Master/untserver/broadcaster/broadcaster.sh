#!/bin/bash

###############################################################
#                                                             #
# Name: Broadcaster                                           #
# Description: Broadcast messages in random order across the  #
# network                                                     #
# Version: 1.0                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

#Gathering data
source "$HOME"/script/servers.sh

dir="$HOME/script/broadcaster"
vardir="$dir/var"
messagedir="$dir/messages.sh"
broadcastlistdir="$dir/broadcast.txt"

#Check if var file exist - Allow the script to know in which state it is
# 0 -> All the list in messages.sh was readed or not used at all
# 1 -> There are still messages to be readed
if [[ ! -e "$vardir" ]]
then
    echo -e "Var file doesn't exist - Creating it"
    echo "0" > "$vardir"
fi

#If var equal 0 -> Get all messages, put the broadcast state to 1 and write all messages in broacast list
if [[ "$(cat "$vardir")" -eq "0" ]]
then
    #Get all user defined messages
    source "$messagedir"
   
    #Array copy
    broadcast=("${message[@]}")

    #Put the script in state 1
    echo "1" > "$vardir"

    #Copy the broadcast messages into the broadcast list
    for j in "${broadcast[@]}"
    do
        echo $j
    done > "$broadcastlistdir"
fi

#If var equal 1 -> Get the remaining messages in the broadcast list and share one message across the network
if [[ "$(cat "$vardir")" -eq "1" ]]
then
    #Construct an array from the broadcast list
    if [[ -e "$broadcastlistdir" ]]
    then
        mapfile broadcast < "$broadcastlistdir"
    else
    	echo "The file $broadcastlistdir does not exist - Deleting $vardir - Please restart the script"
    	rm "$vardir"
        exit 1
    fi

    #Get the array max size
    max=$((${#broadcast[@]} - 1))
    #Get an random number between 0 and the max of the array
    i="$(shuf -i 0-$max -n 1)"

    #Send the message across the whole defined network
    for hostname in $hostslist
    do
        (for server in ${hostservers["$(echo "$hostname" | cut -d. -f1)"]}; do (ssh untserver@"${hostname}" "tmux send-keys -t $server:0 Space Enter; tmux send-keys -t $server:0 \"broadcast FFAA00 ${broadcast[$i]//[$'\r\n']}\" Enter") & done) &
    done

    #Remove the array from memory
    unset -v 'broadcast[i]'
fi

#If there isn't messages left, put var in state 0. Otherwise save remaining messages in broadcastlist
if [[ ${#broadcast[@]} -eq 0 ]]
then
    echo "0" > "$vardir"
    rm "$broadcastlistdir"
else
    for j in "${broadcast[@]}"
    do
       echo $j
    done > "$broadcastlistdir"
fi

echo -e "Message sent"
exit 0
