#!/bin/bash

#Description
#
#S'occupe de faire redémarrer les serveurs et d'envoyer les données vers un serveur distant

#Définition des variables
source "$HOME"/script/servers.sh

date=$(date -d "yesterday" '+%Y-%m-%d-%H-%M')
backupdir="/backup"
hostname="PGAMEUNT-1"

echo -e "Lancement de la procédure quotidienne ! - $date"

i=120
while [ "$i" -ge 0 ]
do
    echo "Redémarrage des serveurs dans $i secondes"
    for server in $servers
    do
        tmux send-keys -t "$server":0 Space Enter
        tmux send-keys -t "$server":0 "say Restart of the server in $i seconds/255/170/0" Enter
    done

    sleep 30

    #Décrémentation
    ((i=i-30))
done

echo -e "Extinction des serveurs !"

for server in $servers
do
    "$HOME"/"$server" stop
    sleep 1
done

#$HOME/script/discord/discord.sh \
#--avatar "https://imgur.com/Ii4SoiK.png" \
#--username "Pasta-Bot" \
#--title "The network is shutdown" \
#--description "Daily reboot in progress !" \
#--color "0xFF0000" \
#--timestamp

echo -e "Vérification des mises à jour LGSM !"
~/pastanetwork update-lgsm

#Supprime les anciennes sauvegardes
ls -1tr /backup | grep "PGAMEUNT-1" | head -n -7 | xargs -d '\n' rm -f --

tar -czvf "/backup/$hostname-$date.tar.gz" /home/untserver/

echo "Envoi des logs vers le serveur principal"
for server in $servers
do
    scp -rpv $HOME/serverfiles/Logs/Server_"$server".log untserver@PMAIN-1:/home/untserver/script/sortor/data/"$server"-"$date".log
    cp  $HOME/serverfiles/Logs/Server_"$server".log /backup/logs/"$server"-"$date".log
done

echo -e "Démarrage des serveurs"
for server in $servers
do
    "$HOME"/"$server" start
    sleep 5
done

echo "Envoi de la backup sur le serveur principal"
scp -rpv "/backup/$hostname-$date.tar.gz" "untserver@PMAIN-1:/backup/servers/$hostname/"

echo "Travail terminé !"
exit 0
