#!/bin/bash

###############################################################
#                                                             #
# Name: DailyMaster                                           #
# Description: Execute the daily routine on other hosts       #
# Version: 1.2                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

#Gathering data
source "$HOME"/script/servers.sh

echo -e "Launching daily procedure !"

#Set the offset to have the correct date on data
date=$(date '+%Y-%m-%d-%H-%M')
backupdir="$HOME/backup/servers"
discorddir="$HOME/discord/alert"

#Verifying if everything is here
[[ -d $backupdir ]] || mkdir -p "$backupdir"

echo -e "Backup date set on $date"

echo -e "Sending discord notification"

#Send that the network is restarting
"$discorddir"/discord.sh --avatar "https://imgur.com/Ii4SoiK.png" --username "Pasta-Bot" --color 0xFFAA00 --image "https://imgur.com/gAJqceG.png"

echo -e "Warning players of the restart !" 

#Broadcasting and shutdown of servers on the list
i=300
while [[ "$i" -ge 0 ]]
do
	echo -e "Restart in $i seconds !"

	#Browsing node list
	for hostname in $hostslist
	do
		#Browsing servers for each node
		for server in ${hostservers["$(echo "$hostname" | cut -d. -f1)"]}
		do
			#Sending a message on each server from each node
			ssh untserver@"${hostname}" "tmux send-keys -t $server:0 Space Enter; tmux send-keys -t $server:0 \"broadcast FFAA00 Restart of the server in $i seconds\" Enter" &
		done
	done

	sleep 30
	((i=i-30))

	if [[ "$i" -eq 0 ]]
	then
		echo -e "Servers will be shutdown now"

        #Store each node's subprocess pid
        declare -A nodepidstop

		#Browsing node list
		for hostname in $hostslist
	    do

		    hostnametrunc=$(echo "$hostname" | cut -d. -f1)

		    ssh untserver@"${hostname}" "[[ -d $backupdir ]] || mkdir -p $backupdir";

            #Execute stop, backup commands in a subprocess
            (
            declare -A serverpidstop; 
            	
            for server in ${hostservers["$hostnametrunc"]}; 
            do 
            	ssh untserver@"${hostname}" "\$HOME/$server stop" & 
            	serverpidstop["$server"]=$!; 
            done; 
            
            wait "${serverpidstop[@]}"; 
            
            echo "The node $hostnametrunc is now down"; 
            
            ssh untserver@"${hostname}" "tar -czvf $backupdir/$hostnametrunc-$date.tar.gz /home/untserver/serverfiles/Servers" #&
            #backuppid=$!;
            
            #wait "$backuppid"; 

            [[ -d $backupdir/$hostnametrunc ]] || mkdir -p "$backupdir/$hostnametrunc"
            
            scp -rp "untserver@${hostname}:$backupdir/$hostnametrunc-$date.tar.gz" "$backupdir/$hostnametrunc" & 
                
            for server in ${hostservers["$hostnametrunc"]}; 
            do 
                ssh untserver@"${hostname}" "\$HOME/$server update-lgsm; \$HOME/$server start" & 
            done; 
                
            echo "The node $hostnametrunc is now up") &
            
            nodepidstop["hostnametrunc"]=$!
            
	    done
	    wait "${nodepidstop[@]}"
	fi
done


