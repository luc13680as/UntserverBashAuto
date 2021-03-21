#!/bin/bash

datedmy=$(date -d "yesterday 13:00" '+%Y-%m-%d')
source "$HOME"/script/servers.sh

echo "Envoie de la notification discord"
$HOME/script/discord/discord.sh \
--avatar "https://imgur.com/T7phJaF.png" \
--username "Pasta-Bot" \
--title "The network has detected a new update " \
--description "Servers are restarting in 5 min" \
--color "0xFFA500" \
--timestamp

echo "Mise à jour dans 5 minutes"
for server in $servers
do
  tmux send-keys -t "$server":0 Space Enter
  tmux send-keys -t "$server":0 "say Detecting a new update: Restart in 5 minutes/255/170/0" Enter
done
sleep 300

echo "Mise à jour dans 1 minute"
for server in $servers
do
  tmux send-keys -t "$server":0 Space Enter
  tmux send-keys -t "$server":0 "say Updating in 1 minute/255/170/0" Enter
done
sleep 60

echo "Arrêt des serveurs"

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
  echo "Copie des logs de $server"
  cp "$HOME"/serverfiles/Logs/Server_"$server".log "$HOME"/script/monitor/data/"$server"-"$datedmy".log
done

echo "Backup en cours"

"$HOME"/pastanetwork backup

echo "Mise à jour du jeu"

"$HOME"/pastanetwork update

for server in $servers
do
  echo "Redémarrage de $server"
  "$HOME"/"$server" start
  sleep 15
done

echo "Envoie de la notification discord"
$HOME/script/discord/discord.sh \
--avatar "https://imgur.com/T7phJaF.png" \
--username "Pasta-Bot" \
--title "The network is online" \
--description "Servers are up and running !" \
--color "0x008000" \
--timestamp

echo "Terminé"
