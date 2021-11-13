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
logbackupdir=$HOME/backup/logs

#Verifying if everything is here
[[ -d $logsdir ]] || mkdir -p "$logsdir"

echo -e "Launching the retrieve process"

#Store each node's subprocess pid
declare -A nodepidstop

for hostname in $hostslist
do
	#Temporary
	hostnametrunc=$(echo "$hostname" | cut -d. -f1)
	(
    ssh untserver@"${hostname}" "[[ -d $logbackupdir ]] || mkdir -p $logbackupdir";
    [[ -d $logbackupdir ]] || mkdir -p $logbackupdir;

	for server in ${hostservers["$hostnametrunc"]};
	do
		if ssh -q untserver@"${hostname}" "test /home/untserver/serverfiles/Logs/Server_${server}_Prev.log";
		then
			echo "File found for $server";

		    #Get the date of the file and apply it to the name
		    logdate=$(ssh untserver@"${hostname}" "date -r \$HOME/serverfiles/Logs/Server_${server}_Prev.log '+%Y-%m-%d-%H-%M'");

		    echo "Date set on $logdate for file $server";

		    ssh untserver@"${hostname}" "mv \$HOME/serverfiles/Logs/Server_${server}_Prev.log \$HOME/serverfiles/Logs/$server-$logdate.log";

            #Get the file and make a backup of it
	        scp -rp untserver@"${hostname}":$HOME/serverfiles/Logs/$server-$logdate.log "$logsdir"/;
	          #Distant copy
            ssh untserver@"${hostname}" "mv \$HOME/serverfiles/Logs/$server-$logdate.log $logbackupdir/";

              #Local copy
            cp "$logsdir/$server-$logdate.log" $logbackupdir;
        fi;
	done) &

	nodepidstop["hostnametrunc"]=$!
done

wait "${nodepidstop[@]}"

echo -e "Files received !"

exit 0
