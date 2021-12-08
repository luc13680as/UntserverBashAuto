#!/bin/bash

###############################################################
#                                                             #
# Name: Updater                                               #
# Description: Update servers on every hosts                  #
# Version: 1.1                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

#Gathering data
source "$HOME"/script/servers.sh

echo -e "Launching update procedure !"

#Set the offset to have the correct date on data
date=$(date '+%Y-%m-%d-%H-%M')
backupdir="$HOME/backup"
serverbackupdir="$backupdir/servers"
discorddir="$HOME/discord/alert"

#Cloud backup with rclone
rcloneremotename="pastaremote"
rclonebucketname="Pastanetwork-Unturned-Dev"

#Verifying if everything is here
[[ -d $serverbackupdir ]] || mkdir -p "$serverbackupdir"

echo -e "Backup date set on $date"

echo -e "Sending discord notification"

#Send that the network is updating
#"$discorddir"/discord.sh --avatar "https://imgur.com/Ii4SoiK.png" --username "Pasta-Bot" --color 0xFFAA00 --image "https://imgur.com/gAJqceG.png"

echo -e "Warning players of the update !" 

#Broadcasting and shutdown of servers on the list
i=120
while [[ "$i" -ge 0 ]]
do
	echo -e "Update in $i seconds !"

	#Browsing node list
	for hostname in $hostslist
	do
		#Browsing servers for each node
		for server in ${hostservers["$(echo "$hostname" | cut -d. -f1)"]}
		do
			#Sending a message on each server from each node
			ssh untserver@"${hostname}" "tmux send-keys -t $server:0 Space Enter; tmux send-keys -t $server:0 \"broadcast FFAA00 Update of the server in $i seconds\" Enter" &
		done
	done

	if [[ "$i" -eq 0 ]]
	then
		echo -e "Servers will be shutdown now"

        #Store each node's subprocess pid
        declare -A nodepidstop

		#Browsing node list
		for hostname in $hostslist
	    do

		    hostnametrunc=$(echo "$hostname" | cut -d. -f1)

            echo "Checking the backup directory of $hostnametrunc"
		    ssh untserver@"${hostname}" "[[ -d $serverbackupdir ]] || mkdir -p $serverbackupdir";

            #Execute stop, backup commands in a subprocess
            (
            declare -A serverpidstop; 
            	
            for server in ${hostservers["$hostnametrunc"]}; 
            do 
            	echo "Stoping server $server"
            	ssh untserver@"${hostname}" "\$HOME/$server stop" > /dev/null & 
            	serverpidstop["$server"]=$!; 
            done; 
            
            wait "${serverpidstop[@]}"; 
            
            echo "The node $hostnametrunc is now down"; 
            
            echo "Backup of the node $hostnametrunc"
            ssh untserver@"${hostname}" "tar -czvf $serverbackupdir/$hostnametrunc-$date.tar.gz /home/untserver/serverfiles/Servers";

            [[ -d $serverbackupdir/$hostnametrunc ]] || mkdir -p "$serverbackupdir/$hostnametrunc";
            
            echo "Receiving backup from the node $hostnametrunc"
            scp -rp "untserver@${hostname}:$serverbackupdir/$hostnametrunc-$date.tar.gz" "$serverbackupdir/$hostnametrunc";

            ssh untserver@"${hostname}" "\$HOME/$(echo "$configcontent" | grep "$hostnametrunc" | cut -d, -f1 | head -1) update";
                
            for server in ${hostservers["$hostnametrunc"]}; 
            do 
            	echo "Starting $server"
                ssh untserver@"${hostname}" "\$HOME/$server start" &
            done; 
                
            echo "The node $hostnametrunc is now up") &
            
            nodepidstop["hostnametrunc"]=$!
            
	    done
	    wait "${nodepidstop[@]}"
	fi

	sleep 30
	((i=i-30))
done

#Send a backup with rclone on the cloud
echo "sending backups to the cloud"
rclone copy "$backupdir" "$rcloneremotename:/$rclonebucketname"

echo "Done !"
