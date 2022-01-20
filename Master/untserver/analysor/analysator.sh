#!/bin/bash

###############################################################
#                                                             #
# Name: Analysator                                            #
# Description: Analyse logs and extract informations          #
# Version: 1.0                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

#Gathering servers data
source "$HOME"/script/servers.sh

#Local informations
scriptdir="${0%/*}"
logscollecteddir=$scriptdir/collected
logsprocesseddir=$scriptdir/processed

#File processing
tmpdir=$scriptdir/tmp
##Servers processing
serverslistFile=$tmpdir/serverslist.csv
serverslistDB=$tmpdir/serverslistDB.csv
serverslistToAdd=$tmpdir/serverslistToAdd.csv
##Players processing
formatedPlayerList=$tmpdir/tmpPlayersFound.csv
formatedPlayerListSteamID=$tmpdir/tmpPlayersFoundSteamID.csv
formatedPlayerListSteamIDonDatabase=$tmpdir/tmpPlayersFoundSteamIDonDatabase.csv
formatedPlayerListSteamIDtoAdd=$tmpdir/tmpPlayersFoundSteamIDtoAdd.csv

#MySQL Informations
mysqlHost=''
mysqlUser=''
mysqlPassword=''
mysqlPort=''
mysqlStatsDatabase=''
mysqlTemplate="$scriptdir/databasecreation.sql"

echo "Checking database connection !"

#Check if the connection and the database exist
#mysql -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "SHOW tables;"
if ! mysql -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -e "USE $mysqlStatsDatabase;"
then
    echo "The database doesn't exist !"
    exit 1
fi

#Check if required tables exist
tablesExist=$(mysql -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "SHOW TABLES;" | grep stats)
if [[ ! "$tablesExist" =~ "stats" ]]
then
    echo "Launching the creation of tables"
    mysql -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" < "$mysqlTemplate"
fi

#Check directory
[[ -d $logscollecteddir ]] || mkdir -p "$logscollecteddir"
[[ -d $logsprocesseddir ]] || mkdir -p "$logsprocesseddir"
[[ -d $tmpdir ]] || mkdir -p "$tmpdir"

#Checking if servers exist in the database
echo "Checking if servers exists in the database"
if [[ ! -z "$serverslist" ]]
then
	echo "$serverslist" | sort > "$serverslistFile"

	#Check if servers are present in the database
	#Crafting the request
    checkServersRequest="SELECT server FROM stats_servers WHERE "
    while IFS= read -r serversToCheck
    do
        checkServersRequest+="server = '$serversToCheck' OR "
    done < "$serverslistFile"
    checkServersRequest=$(echo "$checkServersRequest" | sed 's/ OR $/\;/')

    #Sending the request and collect results
    mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "$checkServersRequest" -N | sort > "$serverslistDB"

    #Getting servers that needs to be added
    grep -vxFf "$serverslistDB" "$serverslistFile" > "$serverslistToAdd"

    #Add servers that needs to be added
    if [[ $(cat "$serverslistToAdd" | wc -l) -gt 0 ]]
    then
    	echo "$(cat "$serverslistToAdd" | wc -l) servers needs to be added in the database"

    	#Crafting request and send it
    	addServerRequest="INSERT INTO \`stats_servers\` (\`server\`) VALUES"
        while IFS= read -r SrvtoAdd
        do
        	addServerRequest+=" ('$SrvtoAdd'),"
        done < "$serverslistToAdd"
        addServerRequest=$(echo "$addServerRequest" | sed 's/,$/;/')
        mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "$addServerRequest" -N

        echo "Servers added to the database !"
    else
    	echo "All servers are already in the database !"
    fi
else
	echo "No servers have been found !! - Please check your configuration file"
	exit 1
fi

echo "Launching data analyse !"
echo "==================================="

#Scan every logs file
for f in "$logscollecteddir"/*.log
do
	echo "Scanning $f..."

	#Retrieving date and server 
	fserver=$(echo "$f" | grep -oP "pastanetwork(?:|[0-9])-" | tr -d '-')
	fdate=$(echo "$f" | grep -oP "[0-9]{4}-[0-9]{2}-[0-9]{2}")

    echo -e "Server: $fserver \nDate: $fdate"

    echo "Retrieving players list and informations !" 

    #Transform data collected into a csv format
    playersInfos=$(cat "$f" | grep -a 'Connecting: PlayerID:' | cut -c 44- | sed -e "s/./\"/" | sed -e "s/ Name\: /\"\,\"/g" | sed -e "s/ Character: /\"\,\"/g" | sed -e "s/$/\"/")

    #Checking if characters have been found before formatting results into a file
    if [[ ! -z "$playersInfos" ]]
    then
        echo "Found $(echo "$playersInfos" | wc -l) characters !"
    else
        echo "No characters have been found !"
        echo "No statistics will be calculated for this file"
        continue
    fi

    #Convert csv file into something exploitable
    #csvkit need a header in order to not throw some errors, so let's give it some.
    #Ensure that any couple steamid-SteamName-Character is unique
    echo "$playersInfos" | csvsort -H -c 1,2,3 | uniq | csvformat -U 2 > "$formatedPlayerList"

    echo "Checking players existence in the database !"

    cat "$formatedPlayerList" | csvcut -c1 | sed '1d' | sort | uniq > "$formatedPlayerListSteamID"

    #Crafting request and send it
    playerExistenceRequest="SELECT steamid FROM stats_players WHERE "
    while IFS= read -r playerSteamID
    do
        playerExistenceRequest+="steamid = $playerSteamID OR "
    done < "$formatedPlayerListSteamID"
    playerExistenceRequest=$(echo "$playerExistenceRequest" | sed 's/ OR $/\;/')

    #Sending the request and collect results
    mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "$playerExistenceRequest" -N | sort > "$formatedPlayerListSteamIDonDatabase"

    #Getting players that needs to be added
    grep -vxFf "$formatedPlayerListSteamIDonDatabase" "$formatedPlayerListSteamID" > "$formatedPlayerListSteamIDtoAdd"

    if [[ $(cat "$formatedPlayerListSteamIDtoAdd" | wc -l) -gt 0 ]]
    then
    	echo "$(cat "$formatedPlayerListSteamIDtoAdd" | wc -l) players needs to be added in the database"

    	#Crafting request and send it
    	addPlayerRequest="INSERT INTO \`stats_players\` (\`steamid\`) VALUES"
        while IFS= read -r SteamIDtoAdd
        do
        	addPlayerRequest+=" ($SteamIDtoAdd),"
        done < "$formatedPlayerListSteamIDtoAdd"
        addPlayerRequest=$(echo "$addPlayerRequest" | sed 's/,$/;/')
        mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "$addPlayerRequest" -N

        echo "Players added to the database !"
    else
    	echo "All players are already in the database !"
    fi

    #exit 0 
    if [[ "$fserver" == "pastanetwork10" ]]
    then
    	exit 0
    fi
done
