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
version="0.6"
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
verbosity=4
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
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
username=jlivin25 #name of the system user doing the backup
source /home/"$username"/bin/standalone_scripts/helper_script.sh
config_file="/home/"$username"/.config/ScriptSettings/config.sys"
stamp=$(echo "`date +%d%m%Y`-`date +%H%M`") #create a timestamp for our backup
lockname=${scriptlong::-3} # reduces the name to remove .sh
script_pid=$(echo $$)
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
   echo -e "\t -s Override set verbosity to specify silent log level"
   echo -e "\t -V Override set verbosity to specify verbose log level"
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
run_backup () {
  tar -cpzf backup.tar.gz \
  --exclude=/backup.tar.gz \
  --exclude=/"$backupfolder" \
  --exclude=/proc \
  --exclude=/tmp \
  --exclude=/opt/calibre \
  --exclude=/mnt \
  --exclude=/dev \
  --exclude=/sys \
  --exclude=/run \
  --exclude=/snap \
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
}
#
#
#+-----------------------+
#+---Set up user flags---+
#+-----------------------+
#get inputs
OPTIND=1
while getopts ":b:u:drsVGh:" opt
do
    case "${opt}" in
      b) backupfolder="${OPTARG}"
      enotify "-b specified, target for backup is: $backupfolder";;
      u) username="${OPTARG}"
      enotify "-u specified, user is: $username";;
      d) dryrun="1"
      enotify "-d specified, running in dry-run mode";;
      r) remote_sync="1"
      enotify "-r specified, calling remote sync at finish";;
      s) verbosity=$silent_lvl
      enotify "-s specified: Silent mode";;
      V) verbosity=$inf_lvl
      enotify "-V specified: Verbose mode";;
      G) verbosity=$dbg_lvl
      enotify "-G specified: Debug mode";;
      h) helpFunction;;
      ?) helpFunction;;
    esac
done
shift $((OPTIND -1))
#
#
#+-----------------+
#+---Adjust PATH---+
#+-----------------+
if [[ -z $username ]]; then
  export PATH="/home/$username/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
fi
#
#
#+------------------+
#+---Start Script---+
#+------------------+
enotify "$scriptlong started"
edebug "PID is: $script_pid"
edebug "Source config file"
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
  einfo "Config file found, using $config_file"
  source "$config_file"
fi
#
#
if [[ $dryrun != "1" ]]; then
  if [[ -d "$backupfolder" ]]; then
    edebug "backup location found, using: $backupfolder"
  else
    edebug "no backup location found, attempting to create: $backupfolder"
    mkdir -p "$backupfolder"
    if [[ "$?" != 0 ]]; then
      edebug "error creating backup location: $backupfolder, please check"
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
      ewarn "tar backup process produced an error, error code $capture"
      rm -r "/tmp/$lockname"
      exit 66
    else
      #if no errors rename backup file and move to local storage
      edebug "tar backup ** "$stamp"_"$sysname"_backup.tar.gz ** completed successfully, moving..."
      mv backup.tar.gz /$backupfolder/"$stamp"_"$sysname"_backup.tar.gz
      capture="$?"
      if [ "$capture" != "0" ]; then
        ewarn "moving created backup failed, error code $capture"
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
      ewarn "tar backup process produced an error, error code $capture"
      rm -r "/tmp/$lockname"
      exit 66
    else
      #if no errors rename backup file and move to local storage
      edebug "tar backup ** "$stamp"_"$sysname"_backup.tar.gz ** completed successfully, moving..."
      mv backup.tar.gz /$backupfolder/"$stamp"_"$sysname"_backup.tar.gz
      capture="$?"
      if [ "$capture" != "0" ]; then
        ewarn "moving created backup failed, error code $capture"
        rm -r "/tmp/$lockname"
        exit 66
      else
        edebug "backup file successfully moved to backupfolder: $backupfolder"
      fi
    fi
  fi
else
  edebug "running in dry-mode, no back-up created"
fi
#
#
#+-----------------+
#+---Remote sync---+
#+-----------------+
if [[ "$remote_sync" == "1" ]]; then
  edebug "running remote sync of backup"
  if [[ "$dryrun" != "1" ]]; then
    cd /$backupfolder/
    #  rclone copy /$backupfolder mediapc-jotta:backup
    #  rclone copy ~/Kodi_Test_Audio/Spring\ -\ Blender\ Open\ Movie.mp4 mediapc-jotta:ubuntu_sys_backups
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
    edebug "dryrun enabled, remote sync section triggered but no files transferred"
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
  eerror "error removing lock directory, /tmp/$lockname"
  exit 65
fi
enotify "$scriptlong completed"
exit 0
