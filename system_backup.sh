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
version="0.3"
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
PATH=/sbin:/bin:/usr/bin:/home/"$username"
source "$HOME"/bin/standalone_scripts/helper_script.sh
log="$HOME"/bin/script_logs/system_backup.sh
stamp=$(echo "`date +%d%m%Y`-`date +%H%M`") #create a timestamp for our backup
sysname="mediapc_test"
backupfolder="/home/$username/SysBackups" #where to store the backups
scriptlong="system_backup.sh" # imports the name of this script
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
#+------------------+
#+---Start Script---+
#+------------------+
enotify "$scriptlong started"
edebug "PID is: $script_pid"
if [[ $dryrun != "1" ]]; then
  if [[ -d "$backupfolder" ]]; then
    edebug "backup location found"
  else
    edebug "no backup location found, attempting to create"
    mkdir -p "$backupfolder"
    if [[ "$?" != 0 ]]; then
      edebug "error creating backup location, please check"
      exit 65
    else
      edebug "successfully created backup folder"
    fi
  fi
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
else
  edebug "running in dry-mode, no back-up created"
fi
#check for errors
if [ "$?" == "0" ]; then
  edebug "backup completed successfully"
  #mv backup.tar.gz /$backupfolder/"$stamp"_"$sysname"_backup.tar.gz
  edebug "tar backup ** $stamp_$sysname_backup.tar.gz ** completed successfully"
else
  capture="$?"
  ewarn "tar backup process produced an error, error code $capture"
  exit 66
fi
#
#
#+---------------------+
#+---Run remote sync---+
#+---------------------+
if [[ "$remote_sync" == "1" ]]; then
  edebug "running remote sync of backup"
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
exit 0 # Exit script after printing help, and all else successful
