#!/usr/bin/env bash
#
###############################################################################################
###                                     "system_backup.sh"                                  ###
### A script designed to help me automate backups of my system.                             ###
### The script contains options to choose just local (default) or carrying out a remote     ###
### backup (using rclone), script needs to be run from root cron job or with 'sudo' rights  ###
###                                                                                         ###
### Use a config script in /home/$USER/.config/ScriptSettings/config.#!/bin/#!/bin/sh and   ###
### set the following variables:                                                            ###
###                                                                                         ###
### sysname="vm_tests" #name of the system to include in backup name                        ###
### backupfolder="/home/jlivin25/SysBackups" #where to store the backups                    ###
### rclone_path="" #self explanatory                                                        ###
### rclone_config="/home/jlivin25/.config/rclone/rclone.conf" #location of rclone.conf      ###
### rclone_method="" #eg. copy                                                              ###
### rclone_remote_name="" #eg. jottacloud                                                   ###
### rclone_remote_destination="" #location in remote backup                                 ###
###                                                                                         ###
###############################################################################################
#
#
#+------------------+
#+---"Exit Codes"---+
#+------------------+
# pick from 64 - 113 (https://tldp.org/LDP/abs/html/exitcodes.html#FTN.AEN23647)
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file/folder error
# exit 66 = Processing Error
# exit 67 = Required Program Missing
#
#
#+------------------------+
#+---"Verbosity Levels"---+
#+------------------------+
#silent_lvl=0
#crt_lvl=1
#err_lvl=2
#wrn_lvl=3
#ntf_lvl=4
#inf_lvl=5
#dbg_lvl=6
#
#
#+---------------------------+
#+---Set Version & Logging---+
#+---------------------------+
version="0.9"
#
#
#+---------------------+
#+---"Set Verbosity"---+
#+---------------------+
verbosity=4
#
#
#+---------------------------------------------+
#+---check running as root before continuing---+
#+---------------------------------------------+
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 66
fi
#
#
#+--------------------------------------------+
#+---"Set Variables & Source helper script"---+
#+--------------------------------------------+
username=root #name of the system user doing the backup
stamp=$(echo "`date +%d%m%Y`-`date +%H%M`") #create a timestamp for our backup
scriptlong="system_backup.sh"
lockname=${scriptlong::-3} # reduces the name to remove .sh
script_pid=$(echo $$)
source /usr/local/bin/helper_script.sh
#
#
#+---------------------------------------+
#+---"check if script already running"---+
#+---------------------------------------+
check_running
#
#
#+-------------------+
#+---Set functions---+
#+-------------------+
helpFunction () {
   echo ""
   echo "Usage: $0 -dG -b /home/bar -u foo"
   echo -e "\t -d Use this flag to specify dry-run mode, no back up will be made"
   echo -e "\t -r Use this flag to specify calling remote sync at end of script"
   echo -e "\t -S Override set verbosity to specify silent log level"
   echo -e "\t -N Override set verbosity to specify notification log level"
   echo -e "\t -V Override set verbosity to specify verbose (info) log level"
   echo -e "\t -G Override set verbosity to specify Debug log level"
   echo -e "\t -b Use this flag to specify folder to backup to, enter as an arguement to this flag"
   echo -e "\t -u Use this flag to specify backup user, enter as an arguement to this flag"

   if [[ -d "/tmp/$lockname" ]]; then
     rm -r "/tmp/$lockname"
   else
     echo "error removing lock directory, /tmp/$lockname"
     exit 65
   fi
   exit 0 # Exit script after printing help, and all else successful
}
#
#
#+-----------------------+
#+---Set up user flags---+
#+-----------------------+
#get inputs
while getopts "drSNVGhu:b:" opt
do
    case ${opt} in
      d) dryrun="1"
      edebug "-d specified, running in dry-run mode";;
      r) remote_sync="1"
      edebug "-r specified, calling remote sync at finish";;
      S) verbosity=$silent_lvl
      edebug "-s specified: SILENT mode logging";;
      N) verbosity=$ntf_lvl
      edebug "-s specified: NOTIFY mode logging";;
      V) verbosity=$inf_lvl
      edebug "-V specified: VERBOSE info mode logging";;
      G) verbosity=$dbg_lvl
      edebug "-G specified: DEBUG mode logging";;
      h) helpFunction;;
      b) backupfolder=${OPTARG}
      edebug "-b specified, target for backup is: $backupfolder"
      backupfolder="${backupfolder:1}";;
      u) username=${OPTARG}
      edebug "-u specified, user is: $username";;
      ?) helpFunction;;
    esac
done
#
#
#+------------------------+
#+---Set or Source Files--+
#+------------------------+
#files or sources requiring username info
config_file="/home/$username/.config/ScriptSettings/config.sh"
#
#
#+-------------------+
#+---Set out backup--+
#+-------------------+
# Folders are relative to '/' folder and --exclude is positionally sensitive
run_backup () {
  tar \
  --exclude="backup.tar.gz" \
  --exclude="home/jlivin25/SysBackups" \
  --exclude="home/jlivin25/SysBackups/*" \
  --exclude="proc" \
  --exclude="tmp" \
  --exclude="opt/calibre" \
  --exclude="mnt" \
  --exclude="lost+found" \
  --exclude="dev" \
  --exclude="sys" \
  --exclude="run" \
  --exclude="snap" \
  --exclude="sys" \
  --exclude="var" \
  --exclude="lib" \
  --exclude="var/log" \
  --exclude="var/cache/apt/archives" \
  --exclude="usr/src/linux-headers*" \
  --exclude="home/*/.gvfs" \
  --exclude="home/*/.cache" \
  --exclude="home/*/Downloads" \
  --exclude="home/*/Music" \
  --exclude="home/*/Videos" \
  --exclude="home/*/temp" \
  --exclude="home/*/.kodi/userdata/Thumbnails" \
  --exclude="home/*/.local/share/Trash" \
  -cpzf backup.tar.gz . /
}
#
#
#+-----------------+
#+---Adjust PATH---+
#+-----------------+
if [[ -z $username ]]; then
  edebug "Setting PATH"
  export PATH="/home/$username/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  edebug "PATH is: $PATH"
fi
#
#
#+------------------+
#+---Start Script---+
#+------------------+
enotify "$scriptlong STARTED"
edebug "PID is: $script_pid"
#
#
#+------------------------------+
#+---Check required variables---+
#+------------------------------+
edebug "Checking for config file"
if [[ ! -f "$config_file" ]]; then
  ewarn "config file $config_file does not appear to exist"
  edebug "attempting to source config file from default location"
  config_file="$HOME/.config/ScriptSettings/config.sh"
  if [[ ! -f "$config_file" ]]; then
    ecrit "config file still not located at $config_file, script exiting"
    rm -r /tmp/"$lockname"
    exit 65
  else
    edebug "located default config file at $config_file, continuing"
    source "$config_file"
  fi
else
  # source config file
  edebug "Config file found, using $config_file"
  source "$config_file"
fi
#
#
#+------------------+
#+---Start Script---+
#+------------------+
if [[ $dryrun != "1" ]]; then
  if [[ -d "$backupfolder" ]]; then
    edebug "backup location found, using: $backupfolder"
  else
    edebug "no backup location found, attempting to create: $backupfolder"
    mkdir -p "$backupfolder"
    if [[ "$?" != 0 ]]; then
      ecrit "error creating backup location: $backupfolder, please check"
      rm -r "/tmp/$lockname"
      exit 65
    else
      edebug "successfully created backup folder: $backupfolder"
    fi
  fi
  edebug "moving to root folder for back up"
  cd / # THIS CD IS IMPORTANT THE FOLLOWING LONG COMMAND IS RUN FROM /
  capture="$?"
  if [ "$capture" != "0" ]; then
    ecrit "moving to root failed, error code $capture"
    rm -r "/tmp/$lockname"
    exit 65
  else
    edebug "moving to root successful"
  fi
  #create the backup name
  backup_result_name=($stamp"_"$sysname"_backup.tar.gz")
  touch backup.tar.gz
  einfo "Local backup started"
  units_of_sleep=5
  if [ -t 0 ]; then #test for tty connection, 0 = connected, else not
    run_backup > /dev/null 2>&1 &
    backup_pid=$!
    pid_name=$backup_pid
    edebug "backup PID is: $backup_pid, recorded as PID_name: $pid_name"
    progress_bar
    capture="$?"
    if [ "$capture" != "0" ]; then
      ecrit "tar backup process produced an error, error code $capture"
      rm -r "/tmp/$lockname"
      exit 66
    else
      #if no errors rename backup file and move to local storage
      edebug "tar backup ** $backup_result_name ** completed successfully, moving..."
      mv backup.tar.gz /$backupfolder/$backup_result_name
      capture="$?"
      if [ "$capture" != "0" ]; then
        ecrit "moving created backup failed, error code $capture"
        rm -r "/tmp/$lockname"
        exit 66
      else
        edebug "...backup file successfully moved to backupfolder: $backupfolder"
        einfo "local backup completed"
      fi
    fi
  else
    run_backup
    capture="$?"
    if [ "$capture" != "0" ]; then
      ecrit "tar backup process produced an error, error code $capture"
      rm -r "/tmp/$lockname"
      exit 66
    else
      #if no errors rename backup file and move to local storage
      backup_result_name=($stamp"_"$sysname"_backup.tar.gz")
      edebug "local backup ** $backup_result_name ** completed successfully, moving..."
      mv backup.tar.gz /$backupfolder/$backup_result_name
      capture="$?"
      if [ "$capture" != "0" ]; then
        ecrit "moving created backup failed, error code $capture"
        rm -r "/tmp/$lockname"
        exit 66
      else
        edebug "...backup file successfully moved to backupfolder: $backupfolder"
        einfo "local backup completed"
      fi
    fi
  fi
else
  sleep 15s
  einfo "running in dry-mode, no back-up created"
fi
#
#
#+-----------------+
#+---Remote sync---+
#+-----------------+
if [[ "$remote_sync" == "1" ]]; then
  edebug "moving to backup folder"
  if [[ "$dryrun" != "1" ]]; then
    einfo "remote backup started"
    cd /$backupfolder
    if [ "$?" != "0" ]; then
      ecrit "moving to backup folder error"
      exit 65
    else
      edebug "successfully moved to backup folder, running remote sync of backup"
    fi
    #set the file to be uploaded
    rclone_source="/$backupfolder/$backup_result_name"
    #grab the size of the backup file
    file_size=$(wc -c "$backup_result_name" | awk '{print $1}')
    edebug "file_size is: $file_size"
    human=$(numfmt --to=iec --field=1 "$file_size")
    edebug "human readable is: $human"
    edebug "performing calc using: $file_size"bytes" / $human"
    #
    #
    if [ -t 0 ]; then #test for tty connection, 0 = connected, else not
      # thanks to here for screen width https://stackoverflow.com/questions/263890/how-do-i-find-the-width-height-of-a-terminal-window
      screen_width=$(stty size | cut -d" " -f2)
      edebug "terminal screen width detected as: $screen_width"
      #remove characters / collums for the [ and ...]!
      screen_width=$((screen_width-16))
      edebug "using: $screen_width"
      # Logic
      # Get estimated transfer time
      # 870mb transferred in 15 mins is same as:
      # 919078572bytes in 900 seconds
      # = 1021198bytes per second
      # SO file_size / 1021198 = number of seconds
      remote_transfer_secs=$((file_size / 1021198))
      remote_transfer_mins=$((remote_transfer_secs / 60))
      edebug "estimated transfer time: $remote_transfer_secs seconds / $remote_transfer_mins mins"
      # SO for sleep units:
      # Divide estimated "minutes to transfer" by "screen size", set sleep to this
      units_of_sleep=$(echo "scale=2 ; $remote_transfer_secs / $screen_width" | bc)
      edebug "units of sleep is calculated as: $units_of_sleep secs"
      #
      #
      edebug "remote backup started"
      sudo -u $username rclone --config="$rclone_config" "$rclone_method" "$rclone_source" "$rclone_remote_name":"$rclone_remote_destination" > /dev/null 2>&1 &
      remotesync_pid=$!
      pid_name=$remotesync_pid
      edebug "remote sync PID is: $remotesync_pid, recorded as PID_name: $pid_name"
      progress_bar
      capture="$?"
      if [ "$capture" != "0" ]; then
        ewarn "remote backup process produced an error, error code $capture"
      else
        edebug "remote backup completed"
      fi
    else
      sudo -u $username rclone --config="$rclone_config" "$rclone_method" "$rclone_source" "$rclone_remote_name":"$rclone_remote_destination"
      capture="$?"
      if [ "$capture" != "0" ]; then
        ewarn "remote backup process produced an error, error code $capture"
      else
        edebug "remote backup completed"
      fi
    fi
  else
    einfo "dryrun enabled, remote sync section triggered but no files transferred"
  fi
else
  edebug "remote backup sync disabled"
fi
#
#
#+----------------+
#+---End Script---+
#+----------------+
if [[ -d "/tmp/$lockname" ]]; then
  edebug "removing lock"
  rm -r "/tmp/$lockname"
  if [ "$?" != "0" ]; then
    ecrit "error removing lock"
    exit 65
  else
    edebug "successfully removed lock"
  fi
else
  ecrit "lock /tmp/$lockname should exist to be removed but no located"
  exit 65
fi
enotify "$scriptlong FINISHED"
exit 0
