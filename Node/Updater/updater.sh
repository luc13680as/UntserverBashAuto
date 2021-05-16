#!/bin/bash

date=$(date '+%Y-%m-%d-%H-%M')
hostname="PGAMEUNT-1"
source "$HOME"/script/servers.sh

echo "Mise à jour dans 5 minutes"
for server in $servers
do
  echo "Redémarrage dans 2 minutes"
  tmux send-keys -t "$server":0 Space Enter
  tmux send-keys -t "$server":0 "say Detecting a new update: Restart in 2 minutes/255/170/0" Enter
done

sleep 120

echo "Mise à jour dans 1 minute"
for server in $servers
do
  echo "Redémarrage dans 1 minute"
  tmux send-keys -t "$server":0 Space Enter
  tmux send-keys -t "$server":0 "say Updating in 1 minute/255/170/0" Enter
done

sleep 60

echo "Arrêt des serveurs"

for server in $servers
do
  echo "Arrêt des serveurs"
  "$HOME"/"$server" stop
done

echo -e "Copie des logs du jour vers le système d'extraction de donnée"

for server in $servers
do
  echo "Copie des logs de $server"
  cp $HOME/serverfiles/Logs/Server_"$server".log /backup/logs/"$server"-"$date".log
  scp -rpv $HOME/serverfiles/Logs/Server_"$server".log untserver@PMAIN-1:/home/untserver/script/sortor/data/"$server"-"$date".log
done

echo "Backup en cours"

tar -czvf "/backup/$hostname-$date.tar.gz" /home/untserver/

echo "Mise à jour du jeu"

"$HOME"/pastanetwork update

for server in $servers
do
  echo "Redémarrage de $server"
  "$HOME"/"$server" start
  sleep 15
done

echo "Terminé"
