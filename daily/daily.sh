#!/bin/bash

#Définition des variables
date=$(date '+%d/%m/%Y - %Hh%M')
datedmy=$(date -d "yesterday 13:00" '+%Y-%m-%d')
logpath="$HOME/script/daily/log"
logfile="$logpath/latest.log"
source "$HOME"/script/servers.sh

echo -e "Lancement de la procédure quotidienne ! - $date"

$HOME/script/discord/discord.sh \
--avatar "https://imgur.com/T7phJaF.png" \
--username "Pasta-Bot" \
--title "The daily reboot will take place in 1 minute" \
--description "You are advised to stop any activities as soon as you can" \
--color "0xFFA500" \
--timestamp

echo -e "Restarting the server in 1 minute"
for server in $servers
do
    tmux send-keys -t "$server":0 Space Enter
    tmux send-keys -t "$server":0 "say Restart of the server in 1 minute/255/170/0" Enter
done

sleep 15

echo -e "Restarting the server in 45 seconds"
for server in $servers
do
    tmux send-keys -t "$server":0 "say Restart of the server in 45 seconds/255/170/0" Enter
done

sleep 15

echo -e "Restarting the server in 30 seconds"
for server in $servers
do
    tmux send-keys -t "$server":0 "say Restart of the server in 30 seconds/255/170/0" Enter
done

sleep 15

echo -e "Restarting the server in 15 seconds"
for server in $servers
do
    tmux send-keys -t "$server":0 "say Restart of the server in 15 seconds/255/170/0" Enter
done

sleep 5

echo -e "Restarting the server in 10 seconds"
for server in $servers
do
    tmux send-keys -t "$server":0 "say Restart of the server in 10 seconds/255/170/0" Enter
done

sleep 5

echo -e "Restarting the server in 5 seconds"
for server in $servers
do
    tmux send-keys -t "$server":0 "say Restart of the server in 5 seconds/255/170/0" Enter
done

sleep 1

echo -e "Restarting the server in 4 seconds"
for server in $servers
do
    tmux send-keys -t "$server":0 "say Restart of the server in 4 seconds/255/170/0" Enter
done

sleep 1

echo -e "Restarting the server in 3 seconds"
for server in $servers
do
    tmux send-keys -t "$server":0 "say Restart of the server in 3 seconds/255/170/0" Enter
done

sleep 1

echo -e "Restarting the server in 2 seconds"
for server in $servers
do
    tmux send-keys -t "$server":0 "say Restart of the server in 2 seconds/255/170/0" Enter
done

sleep 1

echo -e "Restarting the server in 1 second"
for server in $servers
do
    tmux send-keys -t "$server":0 "say Restart of the server in 1 second/255/170/0" Enter
done

sleep 1

echo -e "Extinction des serveurs !"
for server in $servers
do
    "$HOME"/"$server" stop
done

$HOME/script/discord/discord.sh \
--avatar "https://imgur.com/T7phJaF.png" \
--username "Pasta-Bot" \
--title "The network is shutdown" \
--description "Servers are restarting and will be available shortly" \
--color "0xFF0000" \
--timestamp

echo -e "Copie des logs du jour vers le système d'extraction de donnée"
for server in $servers
do
    cp $HOME/serverfiles/Logs/Server_"$server".log $HOME/script/monitor/data/"$server"-$datedmy.log
done

echo -e "Création des backup !"
for server in $servers
do
    $HOME/server backup
done

echo -e "Vérification des mises à jour !"
~/pastanetwork update-lgsm

echo -e "Démarrage des serveurs"
for server in $servers
do
    "$HOME"/"$server" start
    sleep 15
done

$HOME/script/discord/discord.sh \
--avatar "https://imgur.com/T7phJaF.png" \
--username "Pasta-Bot" \
--title "The network is online" \
--description "Servers are up and running !" \
--color "0x008000" \
--timestamp
