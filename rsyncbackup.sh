#!/bin/bash

backup_d="/etc/backup.d/"
machines="machines-enabled"
rsync_cmd="/usr/bin/rsync -razplR --delete --delete-excluded"

for machine in `cat $backup_d$machines`
do
	echo "Backup for $machine"
  source $backup_d$machine

  if [ $destination_host != "local" ] ; then
    destination_folder="$destination_host:$destination_folder"
  else
    destination_folder="$destination_folder$machine"
    if [ ! -d $destination_folder ] ; then
      mkdir -p $destination_folder
    fi
  fi

  for source_folder in $source_folders
  do
    if [ $source_host != "local" ] ; then
      source_folder="$source_host:$source_folder"
    fi

    exclude=""

    if [ -e $backup_d$exclude_from ] ; then
      exclude="$exclude --exclude-from=$backup_d$exclude_from"
    fi

    echo "RSync $source_folder to $destination_folder"
    run_cmd="$rsync_cmd $exclude $source_folder $destination_folder"
    echo $run_cmd
    $run_cmd
  done

  if [ $source_host != "local" ] ; then
    if [ $mysql_user != "" ] ; then

      databases=`mysql --host=$source_host --user=$mysql_user --password=$mysql_pass -e 'SHOW DATABASES;' | grep -Ev '(Database|information_schema)'`

      for database in $databases
      do
        result=`mysqldump --user=$mysql_user --password=$mysql_pass --host=$source_host --skip-opt --add-locks $database | gzip -9 > $destination_folder/$database.gz`
      done
    fi
  fi
done
echo "Done"
