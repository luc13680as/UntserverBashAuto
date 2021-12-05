#!/bin/bash

source "$HOME"/script/servers.sh

#Browsing node list
for hostname in $hostslist
do
    #Browsing servers for each node
    for server in ${hostservers["$(echo "$hostname" | cut -d. -f1)"]}
    do
        ssh untserver@"${hostname}" "tmux send-keys -t "$server":0 Space Enter; tmux send-keys -t "$server":0 'say Saving../255/170/0' Enter; tmux send-keys -t "$server":0 'save' Enter"
    done
done
