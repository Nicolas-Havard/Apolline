#! /bin/bash


fichier='airquality_data_dump.sql'

old_IFS=$IFS # sauvegarde du séparateur de champ
IFS=$'\n' # nouveau séparateur de champ, le caractère fin de ligne
for ligne in $(cat $fichier)
do
	echo $ligne
done
IFS=$old_IFS # rétablissement du séparateur de champ par défaut
