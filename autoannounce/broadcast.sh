#!/bin/bash

#Ce script permet l envoi de message selectionné à partir d une liste dans message.sh

source "$HOME"/script/servers.sh

#Vérifie si le fichier var existe - Permet au script de savoir où il en est
# 0 -> La liste est épuisé ou non chargé donc mise à jour depuis message.sh
# 1 -> La liste de diffusion n est pas épuisé donc on continue de diffuser les messages restants
if [[ ! -e "$HOME/script/autoannounce/var" ]]
then
   echo -e "Le fichier var n'existe pas - Creation en cours"
   echo "0" > "$HOME/script/autoannounce/var"
fi

if [[ "$(cat "$HOME"/script/autoannounce/var)" -eq "0" ]]
then
   source "$HOME/script/autoannounce/messages.sh"
   #Copie le tableau
   broadcast=("${message[@]}")
   echo "1" > "$HOME/script/autoannounce/var"

   #Sauvegarde le tableau dans un fichier texte
   for j in "${broadcast[@]}"
   do
       echo $j
   done > "$HOME/script/autoannounce/broadcast.txt"
fi

if [[ "$(cat "$HOME"/script/autoannounce/var)" -eq "1" ]]
then
    #Lis le tableau depuis un fichier texte
    if [[ -e "$HOME/script/autoannounce/broadcast.txt" ]]
    then
        mapfile broadcast < "$HOME/script/autoannounce/broadcast.txt"
    else
        exit 1
    fi

    #Conversion du maximum de message en l indice max et création de l aléatoire
    max=$((${#broadcast[@]} - 1))
    i="$(shuf -i 0-$max -n 1)"

    #Envoie des messages dans les serveur
    for server in $servers
    do
        tmux send-keys -t "$server":0 Space Enter
        tmux send-keys -t "$server":0 "say ${broadcast[$i]//[$'\r\n']} /255/170/0" Enter
    done

    #Supprime l'élément sélectionner
    unset -v 'broadcast[i]'
fi

#Si on arrive à la fin des messages on repasse en mode 0 sinon on sauvegarde les messages restants
if [[ ${#broadcast[@]} -eq 0 ]]
then
    echo "0" > "$HOME/script/autoannounce/var"
    rm "$HOME/script/autoannounce/broadcast.txt"
else
    for j in "${broadcast[@]}"
    do
       echo $j
    done > "$HOME/script/autoannounce/broadcast.txt"
fi
