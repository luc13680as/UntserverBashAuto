#!/bin/bash

###############################################################
#                                                             #
# Name: Analysator                                            #
# Description: Analyse logs and extract informations          #
# Version: 1.1                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

#Local informations
scriptdir="${0%/*}"
logscollecteddir=$scriptdir/collected
logsprocesseddir=$scriptdir/processed

#MySQL Informations
mysqlHost='localhost'
mysqlUser=''
mysqlPassword=''
mysqlStatsDatabase=''

#Collected

echo "Launching data analyse !"

#Check directory
[[ -d $logscollecteddir ]] || mkdir -p "$logscollecteddir"
[[ -d $logsprocesseddir ]] || mkdir -p "$logsprocesseddir"

for f in "$logscollecteddir"/*.log
do
	echo "Scanning $f..."

	#Retrieving date and server 
	fserver=$(echo "$f" | grep -oP "pastanetwork(?:|[0-9])-" | tr -d '-')
	fdate=$(echo "$f" | grep -oP "[0-9]{4}-[0-9]{2}-[0-9]{2}")

    echo -e "Server: $fserver \nDate: $fdate"

    echo "Retrieving players informations !" 

    #grep 'Connecting: PlayerID:' | sed 's/Connecting: PlayerID: //g'  | sed 's/ Name: /,/g' | sed 's/ Character: /,/g'
    playersInfos=$(cat "$f" | grep -a 'Connecting: PlayerID:' | cut -c 44- | sed -e "s/./\"/" | sed -e "s/ Name\: /\"\,\"/g" | sed -e "s/ Character: /\"\,\"/g" | sed -e "s/$/\"/")
    echo "$playersInfos" > "$scriptdir/tempcsv.csv"
    numbline=$(cat "$scriptdir/tempcsv.csv" | wc -l)

    mapfile -t steamNames < <(echo "$playersInfos" | csvcut -c2)
    mapfile -t unturnedNames < <(echo "$playersInfos" | csvcut -c3)

    i=0
    while [[ $i -le $(($numbline-1)) ]]
    do
    	echo "${unturnedNames[$i]} [${steamNames[$i]}]"
    	i=$((i+1))
    done

    #testfile=$scriptdir/players.csv
    #numbline=$(cat "$testfile" | wc -l)
    #mapfile -t steamNames < <(csvcut -c2 "$testfile")
    #mapfile -t unturnedNames < <(csvcut -c3 "$testfile")

    #i=0
    #while [[ $i -le $(($numbline-1)) ]]
    #do
    #	echo "${unturnedNames[$i]} [${steamNames[$i]}]"
    #	i=$((i+1))
    #done

	exit 0 
done
