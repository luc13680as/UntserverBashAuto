#!/bin/bash

###############################################################
#                                                             #
# Name: Status                                                #
# Description: Check that every server is running             #
# Version: 1.0                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

#Gathering data
source "$HOME"/script/servers.sh

echo -e "Checking every servers"

for hostname in $hostslist
do
        hostnametrunc=$(echo "$hostname" | cut -d. -f1)

        (for server in ${hostservers["$hostnametrunc"]};
        do
                ssh -o LogLevel=error untserver@"${hostname}" "\$HOME/$server monitor";
        done) &
done
