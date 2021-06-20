#!/bin/bash

#Variable
#scriptdir=/backup
scriptdir="${0%/*}"
datadir=$scriptdir/data
infodir=$datadir/info                   #Stocke les informations centralisée
playerdir=$datadir/players              #Stocke les différentes données des joueurs (Kill/Death)
statdir=$datadir/stats          #Stocke les statistiques des différents serveurs
gamechatdir=$datadir/gamechat   #Stocke les conversations en chat
donedir=$datadir/done                   #Stocke les logs une fois les opérations terminées

source /home/untserver/script/sortor/statvar.sh               #Stocke les regex et autres des statistisques

echo -e "Lancement du script de collecte de donnée"

#Vérification des dossiers requis
[[ -d $datadir ]] || mkdir -p "$datadir"; echo -e "Dossier data manquant - Création.. "
[[ -d $infodir ]] || mkdir -p "$infodir"; echo -e "Dossier data/info manquant - Création.. "
#[[ -d $playerdir ]] || mkdir -p "$playerdir" || echo -e "Dossier data/players manquant - Création.. "
[[ -d $statdir ]] || mkdir -p "$statdir"; echo -e "Dossier data/stat manquant - Création.. "
[[ -d $gamechatdir ]] || mkdir -p "$gamechatdir"; echo -e "Dossier data/gamechat manquant - Création.. "
[[ -d $donedir ]] || mkdir -p "$donedir"; echo -e "Dossier data/done manquant - Création.. "

echo -e "Extraction des données en cours"

echo "$datadir/*.log"

if [[ -f "$datadir/*.log" ]]
then
        echo "Aucun fichier a analyser"
        exit 1
fi

#az=0
for f in "$scriptdir"/data/*.log
do
        echo -e "Scan du fichier $f en cours.."

        #Chargement du fichier en mémoire
        ffile=$(cat "$f")

    #Récupération du serveur, de la date et de l'heure
    fserver=$(echo "$f" | grep -oP "pastanetwork(?:-|[0-9]-)" | tr -d '-')
    fdate=$(echo "$f" | grep -oP "[0-9]{4}-[0-9]{2}-[0-9]{2}")
    ftime=$(echo "$f" | grep -oP "[0-9]{2}-[0-9]{2}\." | tr -d '.' | tr -s '-' 'h')

    #Vérification
    if [[ -z "$fserver" ]]
    then
        fserver="unknown"
    fi
    if [[ -z "$fdate" ]]
    then
        fdate="unknown-$RANDOM"
    fi
    if [[ -z "$ftime" ]]
    then
        ftime="05h00"
    fi

    echo -e "Serveur détecté: $fserver \nDate détecté: $fdate \nHeure détecté: $ftime"

    #Création du chemin des info serveurs s'il existe pas
    [[ -d "$infodir"/"$fserver" ]] || mkdir -p "$infodir"/"$fserver"

    echo -e "Récupération des données des joueurs"

    #Collecte l'ip et le nom du joueur associé
    ftmpcsv1=$(echo "$ffile" | grep -oaP "(?:#(?:[0-9]{1,})+ ((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \(((?:[0-9]{1,3}|\.){7}))" | cut -d' ' -f2- | sed 's/\(.*\) (/\1,/g' | sort -t , -k1,1)

    #Collecte le steamid, le nom du joueur et du personnage
    ftmpcsv2=$(echo "$ffile" | grep -oaP "Connecting: PlayerID: (?:(7[0-9]{16}) Name: ((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) Character: ((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}))" | sed 's/Connecting: PlayerID: //g'  | sed 's/ Name: /,/g' | sed 's/ Character: /,/g' | sort -t , -k2,2)

    echo "$ftmpcsv1" > "$infodir"/"$fserver"/"$fserver"-tmp-1.csv
    echo "$ftmpcsv2" > "$infodir"/"$fserver"/"$fserver"-tmp-2.csv
    #Copie du document pour alleger les boucles des statistiques
    finfotmp=$(join -t , -o 1.1 2.3 1.2 2.1  -1 1 -2 2 "$infodir"/"$fserver"/"$fserver"-tmp-1.csv "$infodir"/"$fserver"/"$fserver"-tmp-2.csv)

    #Fait joindre les deux fichiers pour n'en former qu'un
    echo "$finfotmp" >> "$infodir"/"$fserver"/information.csv

    #Nettoyage fichier temporaire
    rm "$infodir"/"$fserver"/"$fserver"-tmp-1.csv "$infodir"/"$fserver"/"$fserver"-tmp-2.csv

    #Reclassement du fichier principal
    sort < "$infodir"/"$fserver"/information.csv | uniq > "$infodir"/"$fserver"/tmpinformation.csv && mv "$infodir"/"$fserver"/tmpinformation.csv "$infodir"/"$fserver"/information.csv

    echo -e "Récupération des messages échangés"

    [[ -e "$gamechatdir"/"$fserver" ]] || mkdir -p "$gamechatdir"/"$fserver"

    mkdir -p "$gamechatdir"/"$fserver"/"$fdate"

    echo "$ffile" | grep -aP "\[World\]" > "$gamechatdir"/"$fserver"/"$fdate"/world.log
    echo "$ffile" | grep -aP "\[Group\]" > "$gamechatdir"/"$fserver"/"$fdate"/group.log
    echo "$ffile" | grep -aP "\[Area\]" > "$gamechatdir"/"$fserver"/"$fdate"/area.log

    #Les statistiques vont être calculées à partir des logs des fichiers
    echo "Préparation des dossiers pour la partie statistique"

    [[ -d $statdir/$fserver/ ]] || mkdir -p "$statdir"/"$fserver"/

    #if [[ -d $statdir/$fserver/tmp/ ]]
    #then
    #    rm $statdir/$fserver/tmp/*
    #else
    #    mkdir -p $statdir/$fserver/tmp
    #fi

    echo "Récupération des messages de mort"

    target=$(echo "$ffile" | sed -E 's/\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] //g')

    echo "Triage des messages de mort"

    i2="${#typedeath[@]}"
    i3="${#deathregex[@]}"

    if [[ ! "$i2" -eq "$i3" ]]
    then
        echo "Fichier statvar.sh configuré de manière incorrect !"
        exit 1
    fi

    i=0
    declare -A deathstorage
    while [[ "$i" -lt "$i2" ]]
    do
        #echo "$target" | grep -Po "${deathregex[$i]}" >> "$statdir/$fserver/tmp/${typedeath[$i]}.log"
        deathstorage["$i"]=$(echo "$target" | grep -Po "${deathregex[$i]}")
        #echo "${deathstorage[$i]}"

        ((i=i+1))
    done

    #Reformatage de la liste des joueurs présents sur le fichier d'information en variable
    finfotmp=$(echo "$finfotmp" | cut -d, -f2 | sort | uniq)

    #Fichier de statistique principal
    statsfile="$statdir/"$fserver"/stats.csv"
    #statsvar=$( (echo "name"; for i in ${typedeath[@],,}; do echo $i; done; echo "kills,deaths,ratio") | tr -s '\n' ',' | sed 's/\,$//')

    [[ -d $statdir/"$fserver" ]] || mkdir -p "$statdir"/"$fserver"
    #[[ -f $statsfile ]] || (echo "name"; for i in ${typedeath[@],,}; do echo $i; done; echo "kills,deaths,ratio") | tr -s '\n' ',' | sed 's/\,$//' > $statsfile
    [[ -f $statsfile ]] || (echo "name"; for ((i = 0 ; i < ${#typedeath[@]} ; i++)); do echo "${typedeath[$i],,}"; done; echo -e "deaths,kills,ratio") | tr -s '\n' ',' | sed 's/\,$/\n/' > $statsfile

    #statsvar=$(cat $statsfile | sed -n '1!p'sed -n '1!p')
    echo "Lecture des joueurs étant mort"

    y=0
    while [[ "$y" -lt "${#deathstorage[@]}" ]]
    do
        if [[ -n "${deathstorage[$y]}" ]]
        then
            while read -r finfotmploop
            do
                echo "Scan du joueur: $finfotmploop"
                finfotmploopescaped=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<<"$finfotmploop")

                playerExist=$(echo "${deathstorage[$y]}" | grep -wo "$finfotmploopescaped")

                if [[ "$?" -eq 0 ]]
                then
                    playerDeath=$(echo "$playerExist" | wc -l)

                    echo "Joueur: $finfotmploop -> $playerDeath"

                    virtualStatLine=$(echo "$statsvar" | grep -w -m1 "$finfotmploopescaped")

                    if [[ "$?" -eq 1 ]]
                    then
                        echo "Joueur non trouvé dans le fichier tmp"

                        if playerStatFile=$(grep -w -m1 "$finfotmploopescaped" < "$statsfile")
                        then
                                echo "Joueur déjà présent dans le fichier statistique. Copie des stats"
                            virtualStatLine=$playerStatFile
                        else
                            echo "Création de l'entrée"
                            #virtualStatLine=$(echo -n "$finfotmploop"; for z in `seq 1 $((${#deathstorage[@]}+3))`; do echo -n ",0";done; echo "")
                            virtualStatLine=$(echo -n "$finfotmploop"; for z in $(seq 1 $((${#deathstorage[@]}+3))); do echo -n ",0";done; echo "")
                        fi
                        statsvar="$statsvar
$virtualStatLine"

                        #virtualStatLine=$(echo -n "$finfotmploop"; for z in `seq 1 ${#deathstorage[@]}`; do echo -n ",0";done; echo "")
                    fi

                    value=$(echo "$virtualStatLine" | cut -d, -f$((y+2)))
                    newvalue=$((value + playerDeath))
                    begin=$(echo "$virtualStatLine" | cut -d, -f1-$((y+1)))
                    end=$(echo "$virtualStatLine" | cut -d, -f$(($y+3))-)

                    statsvar=$(echo "$statsvar" | sed "s/${virtualStatLine}/${begin},${newvalue},${end}/")
                fi
            done < <(echo "$finfotmp")
        fi
        ((y=y+1))
    done

    echo "Fichier temporaire peuplé !"

    echo "Calcul du total"
    statsvar=$(echo "$statsvar" | sed -n '1!p' | awk 'BEGIN{FS=OFS=","} {$33=$2+$3+$4+$5+$6+$7+$8+$9+$10+$11+$12+$13+$14+$15+$16+$17+$18+$19+$20+$21+$22+$23+$24+$25+$26+$27; $34=$28+$29+$30+$31+$32; print}' | awk 'BEGIN{FS=OFS=","} {if ($33 + 0 != 0) $35=sprintf("%.2f",$34/$33)}1')
    #statsvar=$(echo "$statsvar" | awk 'BEGIN{FS=OFS=","} {$33=$2+$3+$4+$5+$6+$7+$8+$9+$10+$11+$12+$13+$14+$15+$16+$17+$18+$19+$20+$21+$22+$23+$24+$25+$26+$27; $34=$28+$29+$30+$31+$32; print}' | awk 'BEGIN{FS=OFS=","} {if ($33 + 0 != 0) $35=sprintf("%.2f",$34/$33)}1')


    echo "Remplacement des valeurs existantes et ajout des nouvelles"

    while read -r playerStatVar
    do
        playerNameStatVar=$(echo "$playerStatVar" | cut -d, -f1)
        playerNameStatVarEscaped=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<<"$playerNameStatVar")

        if playerLineStatFile=$(grep -wF -m1 "$playerNameStatVar" < $statsfile)
        then
                sed -i "s/${playerLineStatFile}/${playerStatVar}/" $statsfile
        else
                echo "$playerStatVar" >> $statsfile
        fi

    done < <(echo "$statsvar")

    statsvar=""
    unset deathstorage

    echo "Traitement terminé"

    #((az=az+1))
    #if [[ $az -eq 1000 ]]
    #then
    #   exit 0
    #fi


    #exit 0

done

echo "Déplacement des logs"

cp /home/untserver/script/sortor/data/done/*.log /backup/logs/
mv -n /home/untserver/script/sortor/data/*.log /home/untserver/script/sortor/data/done/

echo "Fin du script"
