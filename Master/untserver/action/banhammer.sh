#!/bin/bash

###############################################################
#                                                             #
# Name: BanHammer                                             #
# Description: Automatically ban someone on every server      #
# Version: 1.0                                                #
# Creator: luc13680as                                         #
#                                                             #
###############################################################

source "$HOME"/script/servers.sh

discorddir="$HOME/discord/bans"

if [[ $# -eq 0 || $# -gt 4 ]]
then
        echo "[ERROR] Usage: $0 [SteamID] [Reason] [Period in days] [Server]"
        exit 1
elif [[ $# -ge 1 ]]
then
        #Check if the SteamID is correct
    if [[ ! $1 =~ ^7656[0-9]{13}$ ]]
    then
            echo "[ERROR] SteamID64 provided is not valid !"
            exit 1
    else
        steamid=$1
            #Construct the command
        command="ban $steamid"
    fi

    if [[ $# -ge 2 ]]
    then
        if [[ ! $2 =~ [a-zA-Z] ]]
        then
                echo "[ERROR] The reason provided is not a string !"
                exit 1
            else
                if [[ ! $2 == "No reason have been provided" ]]
                then
                        reason=$2
                        #Construct the command
                command="${command}/$reason"
                fi
            fi

            if [[ $# -ge 3 ]]
            then
            if [[ ! $3 =~ ^[0-9]{1,}$ ]]
            then
                echo "[ERROR] Duration entered is not a number !"
                    exit 1
                elif [[ ! $3 -ge 1 ]] || [[ ! $3 -le 365 ]]
                then
                        echo "[ERROR] Time entered is incorrect. Please use a duration between 1 and 365 days"
                        exit 1
                    else
                        duration=$3
                        #Convert from days to seconds
                    durationSecs=$((duration*86400))

                    #Construct the command
                    command="${command}/$durationSecs"
            fi

            if [[ $# -ge 4 ]]
            then
                if [[ ! $4 == "All" ]]
                then
                                for server in $serverslist
                        do
                                if [[ $4 == $server ]]
                                then
                                        targetVerified=1
                                        break
                                fi
                        done

                        if [[ ! targetVerified -eq 1 ]]
                        then
                            echo -e "[ERROR] Server name is incorrect ! Please select one in the list: $(echo $serverslist | tr -s '\n' ' ')"
                                exit 1
                        else
                                targetServ=$4
                                hostnameexec=$(echo $configcontent | tr -s ' ' '\n' | grep $targetServ | cut -d, -f2)
                        fi
                    else
                        hostnameexec="All"
                fi
            fi #If 4 args
            fi #If 3 args
    fi #If 2 args
fi #If 1 arg

#Display what action will be performed
echo ""
echo "Player to ban: $steamid"
[[ -z "$reason" ]] || echo "Reason: $reason"
[[ -z "$durationSecs" ]] || echo "Duration: $duration days or $durationSecs seconds"
[[ -z "$targetServ" ]] || echo "Server: $targetServ"
echo ""
echo "Command: $command"
[[ -z "$targetServ" ]] || echo "Server of execution: $hostnameexec"

if [[ ! -z "$targetServ" ]]
then
        ssh untserver@"${hostnameexec}" "tmux send-keys -t "$targetServ":0 Space Enter; tmux send-keys -t "$targetServ":0 '$command' Enter"
else
    for hostname in $hostslist
        do
                for server in ${hostservers["$(echo "$hostname" | cut -d. -f1)"]}
                do
                        ssh untserver@"${hostname}" "tmux send-keys -t "$server":0 Space Enter; tmux send-keys -t "$server":0 '$command' Enter"
                done
        done
fi

#"$discorddir"/discord.sh --avatar "https://imgur.com/Ii4SoiK.png" --username "Pasta-Guardian" --color 0xFF0000 --image "https://imgur.com/gAJqceG.png" --title "Player $steamid is banned for $duration days" --url "  https://steamcommunity.com/profiles/$steamid" --timestamp
