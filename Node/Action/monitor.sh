#!/bin/bash

source "$HOME"/script/servers.sh

if [[ "$1" == "all" ]]
then
    echo "Envoie du message suivant sur tout les serveurs"
    echo "${@:2}"

    for server in $servers
    do
        tmux send-keys -t "$server":0 Space Enter
        tmux send-keys -t "$server":0 "say ${@:2} /255/170/0" Enter
    done
elif [[ $(echo $servers | grep -oc "$1") -eq 1 ]]
then
    echo "Envoie du message suivant sur $1"
    echo "${@:2}"

    tmux send-keys -t "$1":0 Space Enter
    tmux send-keys -t "$1":0 "say ${@:2} /255/170/0" Enter
else
    echo "Argument incorrect - Veuillez entrer le nom d'un serveur valide"
fi

untserver@Pastanetwork:~/script/action$ cat monitor.sh
#!/bin/bash

source "$HOME"/script/servers.sh

for server in $servers
do
    "$HOME"/"$server" monitor
done
