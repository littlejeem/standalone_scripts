#!/usr/bin/env bash
#
#+-----------------+
#+---"VARIABLES"---+
#+-----------------+
stamp=$(echo "`date +%d%m%Y`-`date +%H_%M_%S`") #create a timestamp for our backup
username=jlivin25#name of the system user doing the backup
sysname=""
#
#
#+-----------------+
#+---MAIN SCRIPT---+
#+-----------------+
mkdir -p /home/"$username"/SysBackups
cd / # THIS CD IS IMPORTANT THE FOLLOWING LONG COMMAND IS RUN FROM /
tar -cvpzf "$stamp"_"$sysname"_backup.tar.gz \
--exclude=/"$stamp"_"$sysname"_backup.tar.gz \
--exclude=/proc \
--exclude=/tmp \
--exclude=/mnt \
--exclude=/dev \
--exclude=/sys \
--exclude=/run \
--exclude=/media \
--exclude=/var/log \
--exclude=/var/cache/apt/archives \
--exclude=/usr/src/linux-headers* \
--exclude=/home/*/.gvfs \
--exclude=/home/*/.cache \
--exclude=/home/$username/Downloads \
--exclude=/home/$username/Music \
--exclude=/home/$username/Videos \
--exclude=/home/$username/SysBackups \
--exclude=/home/$username/temp \
--exclude=/home/*/.local/share/Trash /
if [ $? == "0" ]
 then
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` tar backup ** "$stamp"_"$sysname"_backup.tar.gz ** completed successfully"
 else
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` tar backup process produced an error"
fi
