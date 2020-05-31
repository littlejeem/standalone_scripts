#!/usr/bin/env bash
#
#+-----------------+
#+---"VARIABLES"---+
#+-----------------+
stamp=$(echo "`date +%d%m%Y`-`date +%H_%M_%S`") #create a timestamp for our backup
username=jlivin25 #name of the system user doing the backup
sysname="mediapc_test"
backupfolder="/home/$username/SysBackups"
#
#
#+--------------------+
#+---CHECK FOR SUDO---+
#+--------------------+
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi
#
#
#+-----------------+
#+---MAIN SCRIPT---+
#+-----------------+
mkdir -p $backupfolder
cd / # THIS CD IS IMPORTANT THE FOLLOWING LONG COMMAND IS RUN FROM /
tar -cvpzf /$backupfolder/"$stamp"_"$sysname"_backup.tar.gz \
--exclude=/$backupfolder \
--exclude=/proc \
--exclude=/tmp \
--exclude=/mnt \
--exclude=/dev \
--exclude=/sys \
--exclude=/run \
--exclude=/sys \
--exclude=/media \
--exclude=/var/log \
--exclude=/var/cache/apt/archives \
--exclude=/usr/src/linux-headers* \
--exclude=/home/*/.gvfs \
--exclude=/home/*/.cache \
--exclude=/home/$username/Downloads \
--exclude=/home/$username/Music \
--exclude=/home/$username/Videos \
--exclude=/home/$username/temp \
--exclude=/home/*/.local/share/Trash /
#
#
#+---------------------+
#+---CHECK FOR ERROR---+
#+---------------------+
if [ $? == "0" ]
 then
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` tar backup ** "$stamp"_"$sysname"_backup.tar.gz ** completed successfully"
 else
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` tar backup process produced an error"
fi
