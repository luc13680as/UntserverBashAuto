#!/bin/bash

source "$HOME"/script/servers.sh

for server in $servers
do
    tmux send-keys -t "$server":0 Space Enter
    tmux send-keys -t "$server":0 'say Saving../255/170/0' Enter
    tmux send-keys -t "$server":0 'save' Enter
done

untserver@Pastanetwork:~/script/action$ ccat start2.sh
-bash: ccat: command not found
untserver@Pastanetwork:~/script/action$ cat start2.sh
#!/bin/bash

source "$HOME"/script/servers.sh

if [[ "$#" -eq 0 ]]
then
    echo "Démarrage de tout les serveurs"
    for server in $servers
    do
        "$HOME"/"$server" start
    done

    $HOME/script/discord/discord.sh \
    --avatar "https://imgur.com/Ii4SoiK.png" \
    --username "Pasta-Bot" \
    --title "The network is starting" \
    --description "Network have been started manually by an administrator" \
    --color "0xFF0000" \
    --timestamp

elif [[ $(echo $servers | grep -oc "$1") -eq 1 ]]
then
    echo "Démarrage du serveur $1"
    "$HOME"/"$1" start

    $HOME/script/discord/discord.sh \
    --avatar "https://imgur.com/Ii4SoiK.png" \
    --username "Pasta-Bot" \
    --title "$1 is starting" \
    --description "The server have been started manually by an administrator" \
    --color "0xFF0000" \
    --timestamp
else
    echo "Argument incorrect - Veuillez entrer le nom d'un serveur valide"
fi
