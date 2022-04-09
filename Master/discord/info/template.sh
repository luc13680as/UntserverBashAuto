#!/bin/bash

#Variables
webhooks="https://discord.com/api/webhooks/831649185757265962/_kehmOcmpxWdk5VtASrJ0gxQ3Ih1VK5d0uU3g82aa5lVnqmw4KhOUK9KGA8zRv1qn0Xb"
avatar="https://imgur.com/Ii4SoiK.png"
username="Pasta-Bot"
color="0x008000"

#Args
title="$1"
titleurl="$2"
ip="$3"
port="$4"
location="$5"
map="$6"
gamemode="$7"
type="$8"
reset="$9"
vote="${10}"
stats="${11}"
image="${12}"

echo "$1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12}"

$HOME/discord/source/discord.sh --webhook-url "$webhooks" --avatar "$avatar" --username "$username" --title "$title" --url "$titleurl" --color "$color" --image "$image" \
    --description "**IP:** \`$ip\`\n**Port:** \`$port\`\n**Server location:** $location\n\n**Map:** $map\n**Gamemode:** $gamemode\n**Type:** $type\n**Reset:** $reset\n\n**Vote:** $vote \n**Statistics:** $stats" \
    --image "$image"
