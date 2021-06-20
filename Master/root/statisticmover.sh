#!/bin/bash

servers="pastanetwork pastanetwork2 pastanetwork3 pastanetwork4 pastanetwork5 pastanetwork6"

echo "Copie du fichier statistique de $server"

for server in $servers
do
    echo "Copie du fichier statistique de $server"
    cp /home/untserver/script/sortor/data/stats/"$server"/stats.csv /appli/prod/unturned.pastanetwork.eu/wp-content/uploads/csvfiles/"$server"stats.csv
    chown www-data:www-data /appli/prod/unturned.pastanetwork.eu/wp-content/uploads/csvfiles/"$server"stats.csv
done
