#! /bin/bash

db_request='sensors_request.sql'


old_IFS=$IFS
IFS=$'\n'

nb_lines_request=$(wc -l $db_request | cut -d " " -f1)
nb_lines_done=0
for ligne in $(cat $db_request)
do
	nb_lines_done=$(($nb_lines_done+1))
        #progress=$(bc -l <<< "($nb_lines_done/$nb_lines_request)*100" | cut -d"." -f1)
        #echo "Progression : $progress %\r"
	echo "Progression : $nb_lines_done | $nb_lines_request"
done
IFS=$old_IFS
