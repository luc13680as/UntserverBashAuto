#!/bin/bash

source "$HOME"/script/servers.sh

if [[ "$#" -eq 0 ]]
then
    echo "Arrêt de tout les serveurs"
    for server in $servers
    do
        "$HOME"/"$server" stop
        cp $HOME/serverfiles/Logs/Server_"$server".log $HOME/script/monitor/data/"$server"-$datedmy.log
    done


    $HOME/script/discord/discord.sh \
    --avatar "https://imgur.com/Ii4SoiK.png" \
    --username "Pasta-Bot" \
    --title "The network is shutdown" \
    --description "An administrator shutdown manually the network" \
    --color "0xFF0000" \
    --timestamp

elif [[ $(echo $servers | grep -oc "$1") -eq 1 ]]
then
    echo "Arrêt du serveur $1"
    "$HOME"/"$1" stop
    cp $HOME/serverfiles/Logs/Server_"$1".log $HOME/script/monitor/data/"$1"-$datedmy.log


    $HOME/script/discord/discord.sh \
   --avatar "https://imgur.com/Ii4SoiK.png" \
   --username "Pasta-Bot" \
   --title "$1 is shutdown" \
   --description "An administrator shutdown manually the server" \
   --color "0xFF0000" \
   --timestamp

else
    echo "Argument incorrect - Veuillez entrer le nom d'un serveur valide"
fi
