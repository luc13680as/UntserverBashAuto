#!/bin/bash

#Variable
scriptdir=$HOME/script/monitor
datadir=$scriptdir/data
infodir=$datadir/info                   #Stocke les informations centralisée
playerdir=$datadir/players              #Stocke les différentes données des joueurs (Kill/Death)
statdir=$datadir/stats          #Stocke les statistiques des différents serveurs
gamechatdir=$datadir/gamechat   #Stocke les conversations en chat
donedir=$datadir/done                   #Stocke les logs une fois les opérations terminées

echo -e "Lancement du script de collecte de donnée"

#Vérification des dossiers requis
[[ -d $datadir ]] || mkdir -p "$datadir" || echo -e "Dossier data manquant - Création.. "
[[ -d $infodir ]] || mkdir -p "$infodir" || echo -e "Dossier data/info manquant - Création.. "
#[[ -d $playerdir ]] || mkdir -p "$playerdir" || echo -e "Dossier data/players manquant - Création.. "
[[ -d $statdir ]] || mkdir -p "$statdir" || echo -e "Dossier data/stat manquant - Création.. "
[[ -d $gamechatdir ]] || mkdir -p "$gamechatdir" || echo -e "Dossier data/gamechat manquant - Création.. "
[[ -d $donedir ]] || mkdir -p "$donedir" || echo -e "Dossier data/done manquant - Création.. "

echo -e "Extraction des données en cours"

#Collecte des données
for f in "$scriptdir"/data/*.log
do
    echo -e "Scan du fichier $f en cours.."

    [[ -e "$f" ]] || echo -e "[Erreur] Aucun fichier ne corresponds à ce qui est attendu !" || exit 1

    #Préparation des variables
    fserver=$(echo "$f" | grep -oP "pastanetwork(?:|[0-9])-" | tr -d '-')
    fdate=$(echo "$f" | grep -oP "[0-9]{4}-[0-9]{2}-[0-9]{2}")

    echo -e "Serveur détecté: $fserver \nDate détecté: $fdate"

    [[ -d $infodir/$fserver/ ]] || mkdir -p "$infodir"/"$fserver"/

    echo -e "Récupération des données des joueurs pour la journée du $fdate sur $fserver"

    #Collecte l'ip et le nom du joueur associé
    grep -oaP "(?:#(?:[0-9]{1,})+ ((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \(((?:[0-9]{1,3}|\.){7}))" < "$f" | cut -d' ' -f2- | sed 's/\(.*\) (/\1,/g' | sort -t , -k1,1 > "$infodir"/"$fserver"/"$fserver"-tmp-1.csv

    #Collecte le steamid, le nom du joueur et du personnage
    grep -oaP "Connecting: PlayerID: (?:(7[0-9]{16}) Name: ((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) Character: ((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}))" < "$f" | sed 's/Connecting: PlayerID: //g'  | sed 's/ Name: /,/g' | sed 's/ Character: /,/g' | tr -s ' ' | sort -t , -k2,2 > "$infodir"/"$fserver"/"$fserver"-tmp-2.csv

    #Fait joindre les deux fichiers pour n'en former qu'un
    join -t , -o 1.1 2.3 1.2 2.1  -1 1 -2 2 "$infodir"/"$fserver"/"$fserver"-tmp-1.csv "$infodir"/"$fserver"/"$fserver"-tmp-2.csv >> "$infodir"/"$fserver"/information.csv

    #Copie du document pour les alleger les boucles des statistiques
    join -t , -o 1.1 2.3 1.2 2.1  -1 1 -2 2 "$infodir"/"$fserver"/"$fserver"-tmp-1.csv "$infodir"/"$fserver"/"$fserver"-tmp-2.csv > "$infodir"/"$fserver"/info-copy.csv

    rm "$infodir"/"$fserver"/"$fserver"-tmp-1.csv "$infodir"/"$fserver"/"$fserver"-tmp-2.csv

    #Nettoyage du fichier principal
    sort < "$infodir"/"$fserver"/information.csv | uniq > "$infodir"/"$fserver"/tmpinformation.csv && mv "$infodir"/"$fserver"/tmpinformation.csv "$infodir"/"$fserver"/information.csv

    echo -e "Récupération des messages échangés"

    [[ -e "$gamechatdir"/"$fserver" ]] || mkdir -p "$gamechatdir"/"$fserver"

    mkdir -p "$gamechatdir"/"$fserver"/"$fdate"

    cat "$f" | grep -aP "\[World\]" > "$gamechatdir"/"$fserver"/"$fdate"/world.log
    cat "$f" | grep -aP "\[Group\]" > "$gamechatdir"/"$fserver"/"$fdate"/group.log
    cat "$f" | grep -aP "\[Area\]" > "$gamechatdir"/"$fserver"/"$fdate"/area.log

    echo "Préparation des dossiers"

    [[ -d $statdir/$fserver/ ]] || mkdir -p "$statdir"/"$fserver"/
    mkdir -p "$statdir"/"$fserver"/tmp

    if [[ -d $statdir/$fserver/tmp ]]
    then
        rm -R $statdir/$fserver/tmp
        mkdir -p $statdir/$fserver/tmp
    else
        mkdir -p $statdir/$fserver/tmp
    fi

    echo "Récupération des messages de mort"
    #echo ""$statdir"/"$fserver"/tmp/target.log"
    cat "$f" | sed -E 's/\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] //g' > "$statdir"/"$fserver"/tmp/target.log

    echo "Triage des messages de mort"

    #Death
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] bled to death!" >> "$statdir"/"$fserver"/tmp/Bleeding.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] fractured to death!" >> "$statdir"/"$fserver"/tmp/Bones.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] froze to death!" >> "$statdir"/"$fserver"/tmp/Freezing.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] burned to death!" >> "$statdir"/"$fserver"/tmp/Burning.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] starved to death!" >> "$statdir"/"$fserver"/tmp/Food.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] dehydrated to death!" >> "$statdir"/"$fserver"/tmp/Water.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was mauled by a zombie!" >> "$statdir"/"$fserver"/tmp/Zombie.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was mauled by an animal!" >> "$statdir"/"$fserver"/tmp/Animal.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] killed themself." >> "$statdir"/"$fserver"/tmp/Suicide.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was infected to death!" >> "$statdir"/"$fserver"/tmp/Infection.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] suffocated to death!" >> "$statdir"/"$fserver"/tmp/Breath.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was blown up by a vehicle!" >> "$statdir"/"$fserver"/tmp/Vehicle.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was shredded to bits!" >> "$statdir"/"$fserver"/tmp/Shred.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was blown up by a landmine!" >> "$statdir"/"$fserver"/tmp/Landmine.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was eliminated by the arena!" >> "$statdir"/"$fserver"/tmp/Arena.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was shot by a sentry gun!" >> "$statdir"/"$fserver"/tmp/Sentry.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was blown up by a zombie!" >> "$statdir"/"$fserver"/tmp/Acid.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was crushed by a zombie!" >> "$statdir"/"$fserver"/tmp/Boulder.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was burned by a zombie!" >> "$statdir"/"$fserver"/tmp/Burner.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was dissolved by a zombie!" >> "$statdir"/"$fserver"/tmp/Spit.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was electrocuted by a zombie!" >> "$statdir"/"$fserver"/tmp/Spark.log

    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was shot in the (?:leg|arm|torso|head) by " >> "$statdir"/"$fserver"/tmp/deathGun.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was chopped in the (?:leg|arm|torso|head) by " >> "$statdir"/"$fserver"/tmp/deathMelee.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\] was punched in the (?:leg|arm|torso|head) by " >> "$statdir"/"$fserver"/tmp/deathPunch.log

    #Kill
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "was shot in the (?:leg|arm|torso|head) by ((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\]!" >> "$statdir"/"$fserver"/tmp/killGun.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "was chopped in the (?:leg|arm|torso|head) by ((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\]!" >> "$statdir"/"$fserver"/tmp/killMelee.log
    cat "$statdir"/"$fserver"/tmp/target.log | grep -Po "was punched in the (?:leg|arm|torso|head) by ((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,}) \[((?:[A-Za-z]|[0-9]| |\.|\-|\:|\*|_|\[|\]|\<|\>|\^|\(|\)){1,})\]!" >> "$statdir"/"$fserver"/tmp/killPunch.log

    rm "$statdir"/"$fserver"/tmp/target.log

    #Reformatage de la liste des joueurs présents sur le fichier log
    cat "$infodir"/"$fserver"/info-copy.csv | cut -d, -f2 | sort | uniq > "$statdir"/"$fserver"/tmp/"$fserver".csv
    rm "$infodir"/"$fserver"/info-copy.csv

    statsfile="$statdir/"$fserver"/stats.csv"

    [[ -d $statdir/"$fserver" ]] || mkdir -p "$statdir"/"$fserver"
    [[ -f $statsfile ]] || echo "name,bleeding,bones,freezing,burning,food,water,zombie,animal,suicide,infection,breath,vehicle,shred,landmine,arena,sentry,acid,boulder,burner,spit,spark,deathgun,deathmelee,deathpunch,killgun,killmelee,killpunch,kills,deaths,ratio" > $statsfile

    echo "Lecture des joueurs étant mort"

    for deathlog in $statdir/$fserver/tmp/*.log
    do
        #echo "Lecture de $deathlog"

        if [[ ! -s $deathlog ]] #Si le fichier est vide, supprime le
        then
            #echo "Fichier vide - Suppression"
            #rm $deathlog
            echo "0" > /dev/null
        else
            #echo "Lecture des joueurs étant mort"
            while IFS= read -r playername
            do
                if [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/killGun.log" ]] || [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/killMelee.log" ]] || [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/killPunch.log" ]]
                then
                    result=$(cat "$deathlog" | grep -E "was (:?chopped|punched|shot) in the (?:leg|arm|torso|head) by $playername ")
                    numresult=$(cat "$deathlog" | grep -cE "was (:?chopped|punched|shot) in the (?:leg|arm|torso|head) by $playername ")
                else
                    result=$(cat "$deathlog" | grep "^$playername ")
                    numresult=$(cat "$deathlog" | grep -c "^$playername ")
                fi

                if [[ $numresult -ge 1 ]]
                then
                    lineEdit=$(cat "$statsfile" | grep "^$playername,")
                    lineEditExist=$(cat "$statsfile" | grep -c "^$playername,")
                        if [[ $lineEditExist -eq 0 ]]
                        then
                        echo "Le joueur $playername n'est pas dans le fichier - Ajout de celui-ci"
                                echo -e "$playername,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0" >> "$statsfile"
                        lineEdit=$(cat "$statsfile" | grep "^$playername,")
                        fi

                    echo "Ajout de(s) $numresult mort(s) de $playername au fichier"

                        if [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Bleeding.log" ]]
                        then
                                value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f2)
                                newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f3-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Bones.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f3)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-2)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f4-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Freezing.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f4)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-3)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f5-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Burning.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f5)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-4)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f6-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Food.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f6)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-5)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f7-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Water.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f7)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-6)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f8-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Zombie.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f8)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-7)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f9-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Animal.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f9)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-8)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f10-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Suicide.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f10)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-9)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f11-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Infection.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f11)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-10)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f12-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Breath.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f12)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-11)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f13-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Vehicle.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f13)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-12)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f14-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Shred.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f14)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-13)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f15-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Landmine.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f15)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-14)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f16-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Arena.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f16)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-15)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f17-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Sentry.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f17)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-16)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f18-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Acid.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f18)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-17)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f19-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Boulder.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f19)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-18)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f20-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Burner.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f20)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-19)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f21-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Spit.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f21)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-20)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f22-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/Spark.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f22)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-21)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f23-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/deathGun.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f23)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-22)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f24-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/deathMelee.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f24)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-23)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f25-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/deathPunch.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f25)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-24)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f26-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/killGun.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f26)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-25)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f27-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/killMelee.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f27)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-26)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f28-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                    elif [[ "$deathlog" == ""$statdir"/"$fserver"/tmp/killPunch.log" ]]
                    then
                        value=$(cat "$statsfile" | grep "^$playername," | cut -d, -f28)
                        newvalue=$(echo $(($value + $numresult)))
                        begin=$(cat "$statsfile" | grep "^$playername," | cut -d, -f1-27)
                        end=$(cat "$statsfile" | grep "^$playername," | cut -d, -f29-)
                        sed -i "s/${lineEdit}/${begin},${newvalue},${end}/" $statsfile
                        fi

                    #echo "Le nom du joueur: $playername"
                    #echo "Valeur de base: $value - Nouvelle valeur: $newvalue"
                    #echo "Ligne avant: $lineEdit"
                    #echo "Ligne a écrire: $begin,$newvalue,$end"

                fi


            done < "$statdir"/"$fserver"/tmp/"$fserver".csv

            #echo -e "\n === ETAT FICHIER STAT ==="
            #cat $statsfile
            #echo -e " === ETAT FICHIER STAT ===\n"
        fi
    done

    echo "Suppression du dossier temporaire"
    rm -R $statdir/$fserver/tmp

    echo "Calcul du total pour le ficher de statistique"

    while IFS= read -r statline
    do
        if [[ ! "$statline" == "name,bleeding,bones,freezing,burning,food,water,zombie,animal,suicide,infection,breath,vehicle,shred,landmine,arena,sentry,acid,boulder,burner,spit,spark,deathgun,deathmelee,deathpunch,killgun,killmelee,killpunch,kills,deaths,ratio" ]]
        then
            killgun=$(echo "$statline" | cut -d, -f26)
            killmelee=$(echo "$statline" | cut -d, -f27)
            killpunch=$(echo "$statline" | cut -d, -f28)

            deathvar1=$(echo "$statline" | cut -d, -f2)
            deathvar2=$(echo "$statline" | cut -d, -f3)
            deathvar3=$(echo "$statline" | cut -d, -f4)
            deathvar4=$(echo "$statline" | cut -d, -f5)
            deathvar5=$(echo "$statline" | cut -d, -f6)
            deathvar6=$(echo "$statline" | cut -d, -f7)
            deathvar7=$(echo "$statline" | cut -d, -f8)
            deathvar8=$(echo "$statline" | cut -d, -f9)
            deathvar9=$(echo "$statline" | cut -d, -f10)
            deathvar10=$(echo "$statline" | cut -d, -f11)
            deathvar11=$(echo "$statline" | cut -d, -f12)
            deathvar12=$(echo "$statline" | cut -d, -f13)
            deathvar13=$(echo "$statline" | cut -d, -f14)
            deathvar14=$(echo "$statline" | cut -d, -f15)
            deathvar15=$(echo "$statline" | cut -d, -f16)
            deathvar16=$(echo "$statline" | cut -d, -f17)
            deathvar17=$(echo "$statline" | cut -d, -f18)
            deathvar18=$(echo "$statline" | cut -d, -f19)
            deathvar19=$(echo "$statline" | cut -d, -f20)
            deathvar20=$(echo "$statline" | cut -d, -f21)
            deathvar21=$(echo "$statline" | cut -d, -f21)

            deathgun=$(echo "$statline" | cut -d, -f23)
            deathmelee=$(echo "$statline" | cut -d, -f24)
            deathpunch=$(echo "$statline" | cut -d, -f25)

            deathcount=$(echo $(($deathvar1 + $deathvar2)))
            deathcount=$(echo $(($deathcount + $deathvar3)))
            deathcount=$(echo $(($deathcount + $deathvar4)))
            deathcount=$(echo $(($deathcount + $deathvar5)))
            deathcount=$(echo $(($deathcount + $deathvar6)))
            deathcount=$(echo $(($deathcount + $deathvar7)))
            deathcount=$(echo $(($deathcount + $deathvar8)))
            deathcount=$(echo $(($deathcount + $deathvar9)))
            deathcount=$(echo $(($deathcount + $deathvar10)))
            deathcount=$(echo $(($deathcount + $deathvar11)))
            deathcount=$(echo $(($deathcount + $deathvar12)))
            deathcount=$(echo $(($deathcount + $deathvar13)))
            deathcount=$(echo $(($deathcount + $deathvar14)))
            deathcount=$(echo $(($deathcount + $deathvar15)))
            deathcount=$(echo $(($deathcount + $deathvar16)))
            deathcount=$(echo $(($deathcount + $deathvar17)))
            deathcount=$(echo $(($deathcount + $deathvar18)))
            deathcount=$(echo $(($deathcount + $deathvar19)))
            deathcount=$(echo $(($deathcount + $deathvar20)))
            deathcount=$(echo $(($deathcount + $deathvar21)))
            deathcount=$(echo $(($deathcount + $deathgun)))
            deathcount=$(echo $(($deathcount + $deathmelee)))
            deathcount=$(echo $(($deathcount + $deathpunch)))

            killscount=$(echo $(($killgun + $killmelee )))
            killscount=$(echo $(($killscount + $killpunch)))

            if [[ $deathcount -eq 0 ]]
            then
                deathdivision=1
            else
                deathdivision=$deathcount
            fi
            ratio=$(echo "scale=2;($killscount/$deathdivision)" | bc | sed 's/^\./0\./g')
            ratio=$(sed 's/[\*\.]/\\&/g' <<<"$ratio")

            statlineEdit=$(echo "$statline" | cut -d, -f1-28)

            #echo "Ligne avant: $statline"
            #echo "Ligne apres: $statlineEdit,$killscount,$deathcount"

            sed -i "s/${statline}/${statlineEdit},${killscount},${deathcount},${ratio}/g" $statsfile
        fi

    done < $statsfile

    #exit
    echo "Deplacement du fichier $f vers $donedir"
    mv "$f" "$donedir"

done

echo -e "Scan terminé"
