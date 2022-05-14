#!/bin/bash
while true
do
    rsstail -i 2 -u https://smartlydressedgames.com/rss/unturned-steam-dedicated-server-updates.xml -n 0 | while read line
    do 
        /home/untserver/script/daily/dailymaster.sh update
    done
done
