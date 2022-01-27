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
formatedPlayerListIDonDatabase=$tmpdir/tmpPlayersFoundIDonDatabase.csv
formatedPlayerListIDonStatsDB=$tmpdir/tmpPlayersFoundIDPlayersDB.csv
formatedPlayerListIDonStatsToAdd=$tmpdir/tmpPlayersFoundIDonStatsToAdd.csv
##Unturned Format
tmpPlayersUntFormat=$tmpdir/tmpPlayersUnt.csv
##Messages Processing
declare -A deathRegex
deathRegex["bleeding"]='.{1,} bled to death!'
deathRegex["bones"]='.{1,} fractured to death!'
deathRegex["freezing"]='.{1,} froze to death!'
deathRegex["burning"]='.{1,} burned to death!'
deathRegex["food"]='.{1,} starved to death!'
deathRegex["water"]='.{1,} dehydrated to death!'
deathRegex["zombie"]='.{1,} was mauled by a zombie!'
deathRegex["animal"]='.{1,} was mauled by an animal!'
deathRegex["suicide"]='.{1,} killed themself.'
deathRegex["infection"]='.{1,} was infected to death!'
deathRegex["breath"]='.{1,} suffocated to death!'
deathRegex["vehicle"]='.{1,} was blown up by a vehicle!'
deathRegex["shred"]='.{1,} was shredded to bits!'
deathRegex["landmine"]='.{1,} was blown up by a landmine!'
deathRegex["sentry"]='.{1,} was shot by a sentry gun!'
deathRegex["acid"]='.{1,} was blown up by a zombie!'
deathRegex["boulder"]='.{1,} was crushed by a zombie!'
deathRegex["burner"]='.{1,} was burned by a zombie!'
deathRegex["spit"]='.{1,} was dissolved by a zombie!'
deathRegex["spark"]='.{1,} was electrocuted by a zombie!'
deathRegex["deathgun"]='.{1,} was shot in the (?:leg|arm|torso|head) by '
deathRegex["deathmelee"]='.{1,} was chopped in the (?:leg|arm|torso|head) by '
deathRegex["deathpunch"]='.{1,} was punched in the (?:leg|arm|torso|head) by '
deathRegex["deathroadkill"]='.{1,} was roadkilled by '
deathRegex["deathblownup"]='.{1,} was blown up by .{1,} with (?:a|an) (?:grenade|missile|remote detonator|explosive bullet)!'
deathRegex["killgun"]='was shot in the (?:leg|arm|torso|head) by .{1,}'
deathRegex["killmelee"]='was chopped in the (?:leg|arm|torso|head) by .{1,}'
deathRegex["killpunch"]='was punched in the (?:leg|arm|torso|head) by .{1,}'
deathRegex["killroadkill"]='was roadkilled by .{1,}'
deathRegex["killblownup"]='was blown up by .{1,} with (?:a|an) (?:grenade|missile|remote detonator|explosive bullet)!'

#MySQL Informations
mysqlHost=''
mysqlUser=''
mysqlPassword=''
mysqlPort=''
mysqlStatsDatabase=''
mysqlTemplate="$scriptdir/databasecreation.sql"

echo "Checking database connection !"

#Check if the connection and the database exist
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
	#Save servers in a file to iterate through it
	echo "$serverslist" | sort > "$serverslistFile"

	#Craft the request to check if servers are present in the database
    checkServersRequest="SELECT server FROM stats_servers WHERE "
    while IFS= read -r serversToCheck
    do
        checkServersRequest+="server = '$serversToCheck' OR "
    done < "$serverslistFile"
    checkServersRequest=$(echo "$checkServersRequest" | sed 's/ OR $/\;/')
    #Sending the request and collect results and save it
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
	#f="./collected/pastanetwork1-2021-04-14-05-00.log"
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

    echo "Checking players existence in the database !"

    #Convert csv file into something exploitable
    #csvkit need a header in order to not throw some errors, so let's give it some.
    #Ensure that any couple steamid-SteamName-Character is unique
    echo "$playersInfos" | csvsort -H -c 1,2,3 | uniq | csvformat -U 2 > "$formatedPlayerList"
    cat "$formatedPlayerList" | csvcut -c1 | sed '1d' | sort | uniq > "$formatedPlayerListSteamID"

    #Crafting request and send it
    playerExistenceRequest="SELECT id,steamid FROM stats_players WHERE "
    while IFS= read -r playerSteamID
    do
        playerExistenceRequest+="steamid = $playerSteamID OR "
    done < "$formatedPlayerListSteamID"
    playerExistenceRequest=$(echo "$playerExistenceRequest" | sed 's/ OR $/\;/')
    #Sending the request and collect results
    mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "$playerExistenceRequest" -N | cut -f2 | sort > "$formatedPlayerListSteamIDonDatabase"
    #Getting the list of players that needs to be added
    grep -vxFf "$formatedPlayerListSteamIDonDatabase" "$formatedPlayerListSteamID" > "$formatedPlayerListSteamIDtoAdd"

    #Craft a request to add the list of players if it's needed
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

    #Adding players to the statistics table if it's needed
    #Retrieving ID players in the player table
    mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "$playerExistenceRequest" -N | cut -f1 > "$formatedPlayerListIDonDatabase"
    
    #Retrieving ID servers in the server table
    serverID=$(mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "SELECT id FROM stats_servers WHERE server = '$fserver';" -N)

    #Retrieving ID players in the statistics table
    requestPlayerStatsListID="SELECT steamid_id FROM stats_statistics WHERE server_id = $serverID AND ("
    while IFS= read -r playersID
    do
    	requestPlayerStatsListID+="steamid_id = $playersID OR "
    done < "$formatedPlayerListIDonDatabase"
    requestPlayerStatsListID=$(echo "$requestPlayerStatsListID"")" | sed 's/ OR )$/)\;/')
    #Save IDs to a file
    mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "$requestPlayerStatsListID" -N > "$formatedPlayerListIDonStatsDB"
    
    #Determine which players needs to be added in the database
    grep -vxFf "$formatedPlayerListIDonStatsDB" "$formatedPlayerListIDonDatabase" > "$formatedPlayerListIDonStatsToAdd"

    #Add players in the statistics database
    if [[ $(cat "$formatedPlayerListIDonStatsToAdd" | wc -l) -gt 0 ]]
    then
    	#Crafting request and send it
    	addStatsPlayerRequest="INSERT INTO stats_statistics (steamid_id,server_id) VALUES"
        while IFS= read -r IDSteamIDtoAdd
        do
        	addStatsPlayerRequest+=" ($IDSteamIDtoAdd,$serverID),"
        done < "$formatedPlayerListIDonStatsToAdd"
        addStatsPlayerRequest=$(echo "$addStatsPlayerRequest" | sed 's/,$/;/')
        mysql --force -h "$mysqlHost" -P "$mysqlPort" -u "$mysqlUser" -p"$mysqlPassword" -D "$mysqlStatsDatabase" -e "$addStatsPlayerRequest" -N
    fi

    #Add a new column with unturned format
    mapfile -t formatedPlayerListSTMnme < <(cat "$formatedPlayerList" | csvcut -c 2)
    mapfile -t formatedPlayerListUNTnme < <(cat "$formatedPlayerList" | csvcut -c 3)
    nmbPlr=$(cat "$formatedPlayerList" | wc -l)
    i=0
    rm "$tmpPlayersUntFormat"
    while [[ "$i" -le $((nmbPlr-1)) ]]
    do
        echo "\"${formatedPlayerListUNTnme[$i]} [${formatedPlayerListSTMnme[$i]}]\"" >> "$tmpPlayersUntFormat"
        i=$((i+1))
    done

    paste -d',' "$formatedPlayerList" "$tmpPlayersUntFormat" > ./tmp/tmpCopyPaste.csv
    cat ./tmp/tmpCopyPaste.csv > "$formatedPlayerList"
    rm ./tmp/tmpCopyPaste.csv
    
    echo "Scanning file for deaths and kills."

    #Scan l'entièreté du fichier avec les différentes Regex et grep -o pour avoir seulement la bonne partie
    # + Sauvegarder les résultats par type
    totalDeathInFile=0
    declare -A deathMessage
    for typeOfDeath in "${!deathRegex[@]}"
    do
    	#echo "Variable: $typeOfDeath"
    	deathMessage["$typeOfDeath"]=$(cat $f | cut -c 23- | grep -Pao "${deathRegex[$typeOfDeath]}")

    	if [[ -z "${deathMessage[$typeOfDeath]}" ]]
    	then
    		#echo "No death message of type $typeOfDeath have been found"
    		unset deathMessage["$typeOfDeath"]
    	else
    		totalDeathInFile=$((totalDeathInFile + $(echo "${deathMessage[$typeOfDeath]}" | wc -l)))
    		#echo "Found $(echo "${deathMessage[$typeOfDeath]}" | wc -l) deaths for the type $typeOfDeath !"
    	fi
    done
    echo "Found a total of $totalDeathInFile deaths and kills:"
    echo "${deathMessage[@]}"
    echo ""

    #Boucler sur chaque type de mort
     #Boucler sur chaque nom de joueur + steamid
      #Stocker le steamid et le nom dans deux variables temporaires
      #Lancer la RegEx et compter le nombre de fois que ça match
      #Ajouter dans la requête
    #Lancer la requête

    #https://www.tutorialspoint.com/mysql-mass-update-with-case-when-then-else

    for typeOfDeathFilled in "${!deathMessage[@]}"
    do
    	echo "====="
        echo "Type of death: $typeOfDeathFilled"

        #echo "${deathMessage[$typeOfDeathFilled]}"

        echo "-----"

        while IFS= read -r playersLine
        do
        	playersLineUntFormat=$(echo "$playersLine" | cut -c19-)

            if [[ $typeOfDeathFilled == "deathblownup" ]]
        	then
        		playerNumberOfKill="$(echo "${deathMessage[$typeOfDeathFilled]}" | grep -aF -- "$(echo "${deathRegex[$typeOfDeathFilled]}" | sed 's/.{1,}/'"$playersLineUntFormat"'/' | sed 's/was blown up by.*/was blown up/')" | wc -l)"
        	else
          		playerNumberOfKill="$(echo "${deathMessage[$typeOfDeathFilled]}" | grep -aF -- "$playersLineUntFormat" | wc -l)"
        	fi

        	if [[ "$playerNumberOfKill" -ge 1 ]]
        	then
        		playersLineSteamID=$(echo "$playersLine" | cut -d, -f1)
        		echo "Player: $playersLineUntFormat - SteamID: $playersLineSteamID - Number of occurrences: $playerNumberOfKill"
        	fi
        	#exit 0
        done < <(cat "$formatedPlayerList" | csvcut -c 1,4 | sed '1d')
        #exit 0
    done


    #Faire un tableau avec le joueur avec clé steamid et nom player 
    #cat "$formatedPlayerList" | csvcut -c 1,4 | sed '1d'

    #exit 0 
    echo "========"

    if [[ "$fserver" == "pastanetwork10" ]]
    then
    	exit 0
    fi
done
