#!/bin/bash

###############################################################
#                                                             #
# Name: Analysator                                            #
# Description: Analyse logs and extract informations          #
# Version: 1.0                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

#Local informations
scriptdir="${0%/*}"
logscollecteddir=$scriptdir/collected
logsprocesseddir=$scriptdir/processed

#File processing
tmpdir=$scriptdir/tmp
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
echo "Launching data analyse !"

#Check directory
[[ -d $logscollecteddir ]] || mkdir -p "$logscollecteddir"
[[ -d $logsprocesseddir ]] || mkdir -p "$logsprocesseddir"
[[ -d $tmpdir ]] || mkdir -p "$tmpdir"

for f in "$logscollecteddir"/*.log
do
	echo "Scanning $f..."

	#Retrieving date and server 
	fserver=$(echo "$f" | grep -oP "pastanetwork(?:|[0-9])-" | tr -d '-')
	fdate=$(echo "$f" | grep -oP "[0-9]{4}-[0-9]{2}-[0-9]{2}")

    echo -e "Server: $fserver \nDate: $fdate"

    echo "Retrieving players list and informations !" 

    #grep 'Connecting: PlayerID:' | sed 's/Connecting: PlayerID: //g'  | sed 's/ Name: /,/g' | sed 's/ Character: /,/g' 
    # csvsort -c
    playersInfos=$(cat "$f" | grep -a 'Connecting: PlayerID:' | cut -c 44- | sed -e "s/./\"/" | sed -e "s/ Name\: /\"\,\"/g" | sed -e "s/ Character: /\"\,\"/g" | sed -e "s/$/\"/" | csvsort -H -c 1,2,3 | uniq | csvformat -U 2)
    echo "$playersInfos" > "$formatedPlayerList"

    #Checking if players have been found
    if [[ ! -z "$playersInfos" ]]
    then
        echo "Found $(echo "$playersInfos" | wc -l) players !"
    else
        echo "No players have been found !"

        echo "No statistics will be calculated for this file"

        continue
    fi

    echo "Checking players existence in the database !"

    cat "$formatedPlayerList" | csvcut -c1 | sort | uniq > "$formatedPlayerListSteamID"

    playerExistenceRequest="SELECT steamid FROM stats_players WHERE "
    while IFS= read -r playerSteamID
    do
        playerExistenceRequest+="steamid = $playerSteamID OR "
    done < "$formatedPlayerListSteamID"

    playerExistenceRequest=$(echo "$playerExistenceRequest" | sed 's/ OR $/\;/')

    mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "$playerExistenceRequest" -N | sort > "$formatedPlayerListSteamIDonDatabase"

    grep -vxFf "$formatedPlayerListSteamIDonDatabase" "$formatedPlayerListSteamID" > "$formatedPlayerListSteamIDtoAdd"

    if [[ $(cat "$formatedPlayerListSteamIDtoAdd" | wc -l) -gt 0 ]]
    then
    	echo "$(cat "$formatedPlayerListSteamIDtoAdd" | wc -l) players needs to be added in the database"
    	addPlayerRequest="INSERT INTO \`stats_players\` (\`steamid\`) VALUES"
        while IFS= read -r SteamIDtoAdd
        do
        	addPlayerRequest+=" ($SteamIDtoAdd),"
        done < "$formatedPlayerListSteamIDtoAdd"

        addPlayerRequest=$(echo "$addPlayerRequest" | sed 's/,$/;/')

        mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "$addPlayerRequest" -N

        echo "Done !"
    else
    	echo "All players are already in the database !"
    fi

    #exit 0 

    if [[ "$fserver" == "pastanetwork3" ]]
    then
    	exit 0
    fi
done
