#!/bin/bash

#Gathering data
source "$HOME"/script/servers.sh

#Variables
populationFile="${0%/*}/population.csv"
webhook=""

echo "Launching player population analysis"

if [[ -f "$populationFile" ]]
then
        rm "$populationFile"
fi

discordCMD="\"$HOME\"/discord/source/discord.sh --webhook-url=\"$webhook\" --avatar \"https://imgur.com/Ii4SoiK.png\" --username \"Pasta-Bot\" --color 0xFFAA00 --title \"Player population per server\""

for hostname in $hostslist
do
        for server in ${hostservers["$(echo "$hostname" | cut -d. -f1)"]}
        do
                serverPlayers=$(ssh untserver@"${hostname}" "ls -1a ./serverfiles/Servers/$server/Players/")
                numberCharacter=$(echo "$serverPlayers" | wc -l)
                numberPlayers=$(echo "$serverPlayers" | sed 's/_[0-9]//g' | sort | uniq | wc -l)

                echo "$serverPlayers" >> "$populationFile"

                discordCMD+=" --field \"${server^} - Total of characters;$numberCharacter;true\" --field \"${server^} - Total of unique players;$numberPlayers;true\""
        done
done

#Send the per server report
echo "$discordCMD" | bash

#Construct and send the network report
numberCharacter=$(cat "$populationFile" | sort | uniq | wc -l )
numberPlayers=$(cat "$populationFile" | sed 's/_[0-9]//g' | sort | uniq | wc -l)

"$HOME"/discord/source/discord.sh --webhook-url="$webhook" --avatar "https://imgur.com/Ii4SoiK.png" --username "Pasta-Bot" --color 0xFFAA00 --title "Global player population" \
 --field "Number of characters;$numberCharacter" \
 --field "Number of unique players;$numberPlayers"
