#!/bin/bash

source "$HOME"/script/servers.sh

for server in $servers
do
    tmux send-keys -t "$server":0 Space Enter
    tmux send-keys -t "$server":0 'say Saving../255/170/0' Enter
    tmux send-keys -t "$server":0 'save' Enter
done
