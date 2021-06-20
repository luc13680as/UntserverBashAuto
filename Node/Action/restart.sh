#!/bin/bash

source "$HOME"/script/servers.sh
datedmy=$(date '+%Y-%m-%d-%H-%M')

if [[ "$#" -eq 0 ]]
then
    echo "Redémarrage de tout les serveurs"

    $HOME/script/discord/discord.sh \
    --avatar "https://imgur.com/Ii4SoiK.png" \
    --username "Pasta-Bot" \
    --title "The network is restarting" \
    --description "Servers have been restarted manually by an administrator" \
    --color "0xFF0000" \
    --timestamp

    for server in $servers
    do
        tmux send-keys -t "$server":0 Space Enter
        tmux send-keys -t "$server":0 "say The server is restarting/255/170/0" Enter
        tmux send-keys -t "$server":0 "save" Enter
        sleep 1
        cp $HOME/serverfiles/Logs/Server_"$server".log $HOME/script/monitor/data/"$server"-$datedmy.log
        "$HOME"/"$server" restart
    done

elif [[ $(echo $servers | grep -oc "$1") -eq 1 ]]
then
    echo "Redémarrage du serveur $1"

    $HOME/script/discord/discord.sh \
    --avatar "https://imgur.com/Ii4SoiK.png" \
    --username "Pasta-Bot" \
    --title "$1 is restarting" \
    --description "Server have been restarted manually by an administrator" \
    --color "0xFF0000" \
    --timestamp

    tmux send-keys -t "$server":0 Space Enter
    tmux send-keys -t "$server":0 "say The server is restarting/255/170/0" Enter
    tmux send-keys -t "$server":0 "save" Enter
    sleep 1
    cp $HOME/serverfiles/Logs/Server_"$1".log $HOME/script/monitor/data/"$1"-$datedmy.log
    "$HOME"/"$1" restart
else
    echo "Argument incorrect - Veuillez entrer le nom d'un serveur valide"
fi
