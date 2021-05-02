#!/usr/bin/env bash
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
version="0.8"
#
#
#+---------------------+
#+---"Set Verbosity"---+
#+---------------------+
verbosity=3
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
username=jlivin25 #name of the system user doing the backup
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
   echo "Usage: $0 -b /home/bar -u foo -dV"
   echo -e "\t -b Use this flag to specify folder to backup to, enter as an arguement to this flag"
   echo -e "\t -u Use this flag to specify backup user, enter as an arguement to this flag"
   echo -e "\t -d Use this flag to specify dry-run mode, no back up will be made"
   echo -e "\t -r Use this flag to specify calling remote sync at end of script"
   echo -e "\t -S Override set verbosity to specify silent log level"
   echo -e "\t -N Override set verbosity to specify notification log level"
   echo -e "\t -V Override set verbosity to specify verbose (info) log level"
   echo -e "\t -G Override set verbosity to specify Debug log level"
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
OPTIND=1
while getopts ":b:u:drsNVGh:" opt
do
    case "${opt}" in
      b) backupfolder="${OPTARG}"
      einfo "-b specified, target for backup is: $backupfolder";;
      u) username="${OPTARG}"
      einfo "-u specified, user is: $username";;
      d) dryrun="1"
      einfo "-d specified, running in dry-run mode";;
      r) remote_sync="1"
      einfo "-r specified, calling remote sync at finish";;
      S) verbosity=$silent_lvl
      einfo "-s specified: SILENT mode logging";;
      N) verbosity=$ntf_lvl
      einfo "-s specified: INFO mode logging";;
      V) verbosity=$inf_lvl
      einfo "-V specified: VERBOSE (notify) mode logging";;
      G) verbosity=$dbg_lvl
      einfo "-G specified: DEBUG mode logging";;
      h) helpFunction;;
      ?) helpFunction;;
    esac
done
shift $((OPTIND -1))
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
run_backup () {
  tar -cpzf backup.tar.gz \
  --exclude=backup.tar.gz \
  --exclude=$backup_folder \
  --exclude=$backup_folder/* \
  --exclude=proc/* \
  --exclude=tmp/* \
  --exclude=opt/calibre \
  --exclude=mnt/* \
  --exclude=dev/* \
  --exclude=sys/* \
  --exclude=run/* \
  --exclude=snap/* \
  --exclude=sys/* \
  --exclude=var/* \
  --exclude=lib/* \
  --exclude=var/log \
  --exclude=var/cache/apt/archives \
  --exclude=usr/src/linux-headers* \
  --exclude=home/*/.gvfs \
  --exclude=home/*/.cache \
  --exclude=home/*/Downloads \
  --exclude=home/*/Music \
  --exclude=home/*/Videos \
  --exclude=home/*/temp \
  --exclude=home/*/.kodi/userdata/Thumbnails \
  --exclude=home/*/.local/share/Trash \
  . /
}
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
  touch backup.tar.gz
  enotify "Backup started"
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
      edebug "tar backup ** "$stamp"_"$sysname"_backup.tar.gz ** completed successfully, moving..."
      mv backup.tar.gz /$backupfolder/"$stamp"_"$sysname"_backup.tar.gz
      capture="$?"
      if [ "$capture" != "0" ]; then
        ecrit "moving created backup failed, error code $capture"
        rm -r "/tmp/$lockname"
        exit 66
      else
        edebug "backup file successfully moved to backupfolder: $backupfolder"
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
      edebug "tar backup ** "$stamp"_"$sysname"_backup.tar.gz ** completed successfully, moving..."
      mv backup.tar.gz /$backupfolder/"$stamp"_"$sysname"_backup.tar.gz
      capture="$?"
      if [ "$capture" != "0" ]; then
        ecrit "moving created backup failed, error code $capture"
        rm -r "/tmp/$lockname"
        exit 66
      else
        edebug "backup file successfully moved to backupfolder: $backupfolder"
      fi
    fi
  fi
else
  einfo "running in dry-mode, no back-up created"
fi
#
#
#+-----------------+
#+---Remote sync---+
#+-----------------+
if [[ "$remote_sync" == "1" ]]; then
  edebug "running remote sync of backup"
  if [[ "$dryrun" != "1" ]]; then
    cd /$backupfolder
    if [ "$?" != "0" ]; then
      ecrit "moving to backup folder error"
      exit 65
    else
      edebug "successfully moved to backup folder"
    fi
    if [ -t 0 ]; then #test for tty connection, 0 = connected, else not
      sudo -u $username rclone --config="$rclone_config" "$rclone_method" "$rclone_source" "$rclone_remote_name":"$rclone_remote_destination" > /dev/null 2>&1 &
      remotesync_pid=$!
      pid_name=$remotesync_pid
      edebug "remote sync PID is: $remotesync_pid, recorded as PID_name: $pid_name"
      progress_bar
      capture="$?"
      if [ "$capture" != "0" ]; then
        ewarn "remote backup process produced an error, error code $capture"
      else
        edebug "remote backup completed successfully"
      fi
    else
      sudo -u $username rclone --config="$rclone_config" "$rclone_method" "$rclone_source" "$rclone_remote_name":"$rclone_remote_destination"
      capture="$?"
      if [ "$capture" != "0" ]; then
        ewarn "remote backup process produced an error, error code $capture"
      else
        edebug "remote backup completed successfully"
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
  rm -r "/tmp/$lockname"
else
  ecrit "error removing lock directory, /tmp/$lockname"
  exit 65
fi
enotify "$scriptlong FINISHED"
exit 0
