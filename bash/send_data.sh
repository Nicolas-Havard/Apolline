
#!/bin/bash

#################################################################################################################################################################
##############																	  ###############
##############		SCRIPT BASH PERMETTANT DE RECUPERER LES VARIABLES DES BASES DE DONNEES LOCALES ET DE LES ENVOYER VERS INFLUX DB           ###############
##############			   		NECESSITE D'ETRE DANS LE MEME DOSSIER QUE CELUI DES BASES CONTENANT LES DONNEES                   ###############
##############																	  ###############
#################################################################################################################################################################

SILENT_MODE=0												# Si SILENT_MODE = 1, désactive les echo



if [ $SILENT_MODE = 0 ]; then echo "Implentation des variables"; fi

# Variables utilisées hors script (chemin, fichier, ...)
db='sensors.db'                                                                 # Base de donnée sur laquelle sont stockées les données des capteurs
db_request='sensors_request.sql'                                                # fichier ou se trouvent les donnees a envoyer par le noeud issues de la requete sql

# Variables utilisées dans le script
nodename=$(hostname)
URL='http://apolline.lille.inria.fr'
send_port=8086
app_port=8083
influxDB_database='airquality'



if [ $SILENT_MODE = 0 ]; then echo "Debut du script"; fi

#####################################################              DATABASE PART               #########################################################################


if [ $SILENT_MODE = 0 ]; then echo "Préparation de la base de donnée $db présente sur le noeud '$nodename'"; fi
sqlite3 $db 'SELECT data.sensor_identifier, data.data, data.poll_time FROM data JOIN polls ON polls.created=data.poll_time WHERE polls.sent=0 ORDER BY polls.created;' > "$db_request"
# On effectue une requête SQL sur $db (sensors.db) pour récupérer les valeurs des données et leur origine, en ne récupérant que les données non envoyées sur influxDB. Ces données sont ensuite stockées sur 
# $db_request ('sensors'_request.sql')

if [ $SILENT_MODE = 0 ]; then echo "\n\n"; fi
if [ $SILENT_MODE = 0 ]; then echo "Lecture de la base de donnée $db à envoyer sur le serveur"; fi


#####################################################            REQUEST READING               #########################################################################


old_IFS=$IFS                                                            # sauvegarde du séparateur de champ
IFS=$'\n'                                                               # nouveau séparateur de champ, le caractère fin de ligne
nb_lines_request=$(wc -l $db_request | cut -d" " -f1)
nb_lines_done=0
timestamp_old=0

if [ $SILENT_MODE = 0 ]; then echo "Envoie des données de la base vers $URL:$send_port"; fi

for ligne in $(cat $db_request)
do
	sensor=$(echo "$ligne" | cut -d'|' -f1)
        value=$(echo "$ligne" | cut -d'|' -f2)
        timestamp=$(echo "$ligne" | cut -d'|' -f3)
	timestamp=$(($timestamp*1000000000))
        echo "$sensor | $value | $timestamp">>sensors.data_pushed

        site="$URL:$send_port/write?db=$influxDB_database"
        data="$sensor,hostname=$nodename value=$value $timestamp"

	while :
	do
		http_status=$(curl -o /dev/null --silent --write-out '%{http_code}\n' -XPOST $site --data-binary $data)
		if [ $http_status -eq 204 ]
	        then
                	nb_lines_done=$(($nb_lines_done+1))
			progress=$(echo "scale=2; $nb_lines_done/$nb_lines_request*100" | bc)
	                progress=${progress/.*}
	                #if [ $SILENT_MODE = 0 ]; then 
			echo -ne "Progression : $nb_lines_done | $nb_lines_request ($progress%)\r" #; fi
	                break
	        else
	                echo "Erreur $http_status : nouvel envoi"
	                sleep 10
		fi
	done

        if [ $timestamp_old -ne $timestamp ]
        then
                timestamp_old=$(($timestamp_old/1000000000))
                update='UPDATE polls SET sent='1' WHERE created='$timestamp_old';'

                sqlite3 $db $update                  # pas de probleme car timestamp est unique
                timestamp_old=$timestamp
        #else                                                   # Deja envoyé
        fi                # Suppression dans la base de données locale ?
done
IFS=$old_IFS                                                            # rétablissement du séparateur de champ par défaut






#####################################################            INFLUXDB PART              #########################################################################



if [ $SILENT_MODE = 0 ]; then echo "Suppression des fichiers temporaires"; fi                                                            # Suppression du fichier texte contenant les variables à envoyer
rm -rf $db_request

#if (SILENT_MODE == 0); then echo "Redirection vers la base InfluxDB : $URL:$app_port"; fi                                                       # Utile en cas de test
#xdg-open $URL:$app_port
if [ $SILENT_MODE = 0 ]; then echo "Fin du script"; fi



