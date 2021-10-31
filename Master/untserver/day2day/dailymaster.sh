#!/bin/bash

###############################################################
#                                                             #
# Name: DailyMaster                                           #
# Description: Execute the daily routine on other hosts       #
# Version: 1.0                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

#Gathering data
source "$HOME"/script/servers.sh

echo -e "Launching daily procedure !"

#Set the offset to have the correct date on data
date=$(date -d "yesterday" '+%Y-%m-%d-%H-%M')
backupdir="/backup"

echo -e "Backup date set on $date"

#Send that the network is restarting
"$HOME"/script/discord/discord.sh --avatar "https://imgur.com/Ii4SoiK.png" --username "Pasta-Bot" --color 0xFFAA00 --image "https://imgur.com/gAJqceG.png"

#Broadcasting and shutdown of servers on the list
i=120
while [[ "$i" -ge 0 ]]
do
	#Browsing node list
	for hostname in $hostslist
	do
		#Browsing servers for each node
		for server in ${hostservers["$(echo "$hostname" | cut -d. -f1)"]}
		do
			ssh untserver@"${hostname}" "tmux send-keys -t $server:0 Space Enter; tmux send-keys -t $server:0 \"broadcast FFAA00 Restart of the server in $i seconds\" Enter"
		done
	done

	sleep 30
	((i=i-30))

	if [[ "$i" -eq 0 ]]
	then
		echo -e "Shutting down of servers"

		#Browsing node list
		for hostname in $hostslist
	    do
	    	#Browsing servers for each node
		    for server in ${hostservers["$(echo "$hostname" | cut -d. -f1)"]}
		    do
		    	echo "Shutdown of $server on $hostname"
			    ssh untserver@"${hostname}" "\$HOME/$server stop"
			    sleep 1
		    done

		    #Send that the node is down
            #0xFF0000
            
	    done
	fi
done

echo "Backup of each node"
for hostname in $hostslist
do
	hostnametrunc=$(echo "$hostname" | cut -d. -f1)

	#Making the backup
	ssh untserver@"${hostname}" "tar -czvf /backup/$hostnametrunc-$date.tar.gz /home/untserver/"

	for server in ${hostservers["$hostnametrunc"]}
	do
		#Copy the log file on local host
		ssh untserver@"${hostname}" "cp \$HOME/serverfiles/Logs/Server_$server.log /backup/logs/$server-$date.log"
		
		#Retrieving logs file
		scp -rpv untserver@"${hostname}":"\$HOME/serverfiles/Logs/Server_$server.log" "/home/untserver/script/sortor/data/$server-$date.log"

        #Does not restart the server on a certain time of the week
		if [[ ! $(date +%u) -eq 1 ]]
		then
			ssh untserver@"${hostname}" "\$HOME/$server update-lgsm; \$HOME/$server start"
		fi

	done

	#Send that the node is up
    #0x008000

	#Transfert the backup here
	scp -rpv "untserver@${hostname}:/backup/$hostnametrunc-$date.tar.gz" "/backup/servers/$hostnametrunc/"

done

echo "Done !"
