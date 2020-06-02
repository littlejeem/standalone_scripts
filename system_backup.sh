#!/usr/bin/env bash
#
#+-----------------+
#+---"VARIABLES"---+
#+-----------------+
stamp=$(echo "`date +%d%m%Y`-`date +%H%M`") #create a timestamp for our backup
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
touch backup.tar.gz
tar -cvpzf backup.tar.gz \
--exclude=/backup.tar.gz \
--exclude=/$backupfolder \
--exclude=/proc \
--exclude=/tmp \
--exclude=/mnt \
--exclude=/dev \
--exclude=/sys \
--exclude=/run \
--exclude=/sys \
--exclude=/var \
--exclude=/lib \
--exclude=/media \
--exclude=/var/log \
--exclude=/var/cache/apt/archives \
--exclude=/usr/src/linux-headers* \
--exclude=/home/*/.gvfs \
--exclude=/home/*/.cache \
--exclude=/home/*/Downloads \
--exclude=/home/*/Music \
--exclude=/home/*/Videos \
--exclude=/home/*/temp \
--exclude=/home/*/.kodi/userdata/Thumbnails \
--exclude=/home/*/.local/share/Trash /
#
#
#+---------------------+
#+---CHECK FOR ERROR---+
#+---------------------+
if [ $? == "0" ]
 then
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` backup completed successfully"
  mv backup.tar.gz /$backupfolder/"$stamp"_"$sysname"_backup.tar.gz
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` tar backup ** "$stamp"_"$sysname"_backup.tar.gz ** completed successfully"
  exit 0
 else
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` tar backup process produced an error"
  exit 1
fi
