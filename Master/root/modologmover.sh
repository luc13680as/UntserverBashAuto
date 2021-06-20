#!/bin/bash

#Copie des résultats pour les modérateurs

cp -R /home/untserver/script/sortor/data/gamechat/ /home/stalinorynque/
cp -R /home/untserver/script/sortor/data/info/ /home/stalinorynque/
cp /home/untserver/script/sortor/data/done/*.log /home/stalinorynque/logs/

chown -R stalinorynque:stalinorynque /home/stalinorynque/
