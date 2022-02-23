#!/usr/bin/env bash
#
#
###########################################################################################################
###                                                 "INFO"                                              ###
### A collection of useful commands and functions used as reusable code. In my scripts, the script is   ###
### part of my 'standalone_scripts' repository and should be simlinked to a static folder, the standard ###
### in my scripts will be /usr/local/bin.                                                               ###
### e.g: sudo ln -s /home/$USER/bin/standalone_scripts/helper_script.sh /usr/local/bin/helper_script.sh ###
###########################################################################################################
#
#+---------------+
#+---"VERSION"---+
#+---------------+
version=0.3
#
#
#+-----------------------+
#+---"LOGGING COLOURS"---+
#+-----------------------+
#KEY
#Black        0;30 = colblk   Dark Gray     1;30
#Red          0;31 = colred    Light Red     1;31
#Green        0;32 = colgrn   Light Green   1;32
#Brown/Orange 0;33 = colbor   Yellow        1;33 = colylw
#Blue         0;34 = colblu    Light Blue    1;34 = collblu
#Purple       0;35 = colpur    Light Purple  1;35
#Cyan         0;36 = colcyn    Light Cyan    1;36
#Light Gray   0;37 = collgy
#reset text   0    = colrst
colwht='\033[1;37m' # White - Regular
colblk='\033[0;30m' # Black - Regular
colblu='\034[0;34m' # Blue
colred='\033[0;31m' # Red
colgrn='\033[0;32m' # Green
colylw='\033[0;33m' # Yellow
colbor='\033[0;33m' # Brown/Orange
colpur='\033[0;35m' # Purple
colcyn='\036[0;36m' # Cyan
colrst='\033[0m'    # Text Reset
# Extra colours
collblu='\033[1;34m'
collgy='\037[0;37m'
coldgy='\130[1;30m'
#
#
#+-------------------------+
#+---"LOGGING FUNCTIONS"---+
#+-------------------------+
# all credit here: http://www.ludovicocaldara.net/dba/bash-tips-4-use-logging-levels/
#
### verbosity levels
silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
ntf_lvl=4
inf_lvl=5
dbg_lvl=6
#
## esilent prints output even in silent mode
# terminal versions
tty -s && esilent () { verb_lvl=$silent_lvl tlog "$@"; }
tty -s && ecrit ()  { verb_lvl=$crt_lvl tlog "${colpur}FATAL${colrst} --- $*"; }
tty -s && eerror () { verb_lvl=$err_lvl tlog "${colred}ERROR${colrst} --- $*"; }
tty -s && ewarn ()  { verb_lvl=$wrn_lvl tlog "${colylw}WARNING${colrst} -- $*"; }
tty -s && enotify () { verb_lvl=$ntf_lvl tlog "${colwht}NOTICE${colrst} -- $*"; }
tty -s && einfo ()  { verb_lvl=$inf_lvl tlog "${colwht}INFO${colrst} ---- $*"; }
tty -s && edebug () { verb_lvl=$dbg_lvl tlog "${colgrn}DEBUG${colrst} --- $*"; }
tty -s && eok ()    { verb_lvl=$ntf_lvl tlog "${colrst}SUCCESS${colrst} -- $*"; }
tty -s && edumpvar () { for var in "$@" ; do edebug "$var=${!var}" ; done }
# syslog versions
tty -s || esilent () { verb_lvl=$silent_lvl slog "["$(basename $0)"]" "$@"; }
tty -s || ecrit ()  { verb_lvl=$crt_lvl slog "["$(basename $0)"]" "FATAL --- $*"; }
tty -s || eerror () { verb_lvl=$err_lvl slog "["$(basename $0)"]" "ERROR --- $*"; }
tty -s || ewarn ()  { verb_lvl=$wrn_lvl slog "["$(basename $0)"]" "WARNING -- $*"; }
tty -s || enotify () { verb_lvl=$ntf_lvl slog "["$(basename $0)"]" "NOTICE -- $*"; }
tty -s || einfo ()  { verb_lvl=$inf_lvl slog "["$(basename $0)"]" "INFO ---- $*"; }
tty -s || edebug () { verb_lvl=$dbg_lvl slog "["$(basename $0)"]" "DEBUG --- $*"; }
tty -s || eok ()    { verb_lvl=$ntf_lvl slog "["$(basename $0)"]" "SUCCESS -- $*"; }
tty -s || edumpvar () { for var in "$@" ; do edebug "$var=${!var}" ; done }
# Terminal log function for terminal
tlog() {
  if [ $verbosity -ge $verb_lvl ]; then
    datestring=$(date +%b" "%-d" "%T)
    echo -e "$datestring" "$HOSTNAME" "$USER" \[$lockname\] "$@"
  fi
}
# Error log function for syslog
slog() {
  if [ $verbosity -ge $verb_lvl ]; then
    logger "$@"
  fi
}
#
#
#

#+--------------------------+
#+---"PUSHOVER FUNCTIONS"---+
#+--------------------------+
pushover ()
{
  curl -sS --form-string token="$application_token" --form-string user="$user_token" --form-string title="$pushover_title" --form-string message="$message_form" https://api.pushover.net/1/messages.json > /dev/null
}
#
#
#+----------------------+
#+---"KODI FUNCTIONS"---+
#+----------------------+
update_videolibrary () {
  curl -sS --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodi_VIDEO_assembly > /dev/null
}
#
update_musiclibrary () {
  curl -sS --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly > /dev/null
}
#
clean_videolibrary () {
  curl -sS --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodi_VIDEO_assembly > /dev/null
}
#
clean_musiclibrary () {
  curl -sS --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly > /dev/null
}
#
#
#+---------------+
#+---Timestamp---+
#+---------------+
#
#As this is used to replicate syslog in Logging Functiosn should it not be the same format? <-- Dec  7 20:48:52 testbed-1804
#
timestamp ()
{
  echo "$(date +%b"  "%-d" "%T)" " "$1
}
#
#
#+------------------+
#+---"EXIT CODES"---+
#+------------------+
#
# pick from 64 - 113 (https://tldp.org/LDP/abs/html/exitcodes.html#FTN.AEN23647)
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file error
# exit 66 = Processing Error
# exit 67 = Required Program Missing
#
#place this in parent script immediately after the child script exits
#reply=$?
script_exit ()
{
  reply=$?
  if [[ "$reply" = 0 ]]; then
    ntf_lvl "$scriptlong exited gracefully"
  elif [[ "$reply" = 64 ]]; then
    eerror "Exit code: $reply received"
    edebug "Script $scriptlong exited with 'Variable' error"
  elif [[ "$reply" = 65 ]]; then
    eerror "Exit code: $reply received"
    edebug "Script $scriptlong exited with 'sourcing script or config' error"
  elif [[ "$reply" = 65 ]]; then
    eerror "Exit code: $reply received"
    edebug "Script $scriptlong exited with 'Processing' error"
  elif [[ "$reply" = 66 ]]; then
    eerror "Exit code: $reply received"
    edebug "Script $scriptlong exited with 'Missing Program' error"
  elif [[ "$reply" = 1 ]]; then
    eerror "Exit code: $reply received"
    edebug "Script $scriptlong exited with generic bash error"
  fi
}
#
#
#+--------------------------------+
#+---"VARIABLE & PROGRAM TESTS"---+
#+--------------------------------+
#"Check if already runnng"
# Function for insertion at beginning of scripts to check for existing tmp directory named using 'lockname' at start of script
# If detects folder it will put the usings script into a holding 'while' loop until already running script exits
# Using a folder as this is create using atomic timing and helps prevent race conditions
check_running () {
  if [[ -d /tmp/"$lockname" ]]; then
    while [[ -d /tmp/"$lockname" ]]; do
      ewarn "previous script still running"
      sleep 2m; done
      #  else
      edebug "no previously running script detected"
  fi
  edebug "Attempting to lock script"
  mkdir /tmp/"$lockname"
  if [[ $? = 0 ]]; then
    edebug "temp dir is set as successfully as: /tmp/$lockname"
  else
    eerror "setting temp directory unsuccessfull, exiting"
    exit 65
  fi
}
#
fatal_missing_var () {
 if [[ -z "${JAIL_FATAL}" ]]; then
  eerror "Failed to find: $JAIL_FATAL, JAIL_FATAL is unset or set to the empty string, script cannot continue. Exiting!"
  rm -r /tmp/"$lockname"
  exit 64
 else
  einfo "variable found, using: $JAIL_FATAL"
 fi
}
#
debug_missing_var () {
 if [[ -z "${JAIL_DEBUG}" ]]; then
  edebug "JAIL_DEBUG $JAIL_DEBUG is unset or set to the empty string, may cause issues"
 else
  einfo "variable found, using: $JAIL_DEBUG"
 fi
}
#
#you must pass the completed variable program_check to this function, eg program_check=unzip
prog_check () {
  if ! command -v "$program_check" &> /dev/null
  then
    ewarn "$program_check could not be found, script won't function wihout it, attempting install"
    DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null
#    apt update > /dev/null 2>&1
    DEBIAN_FRONTEND=noninteractive apt-get install -qq "$program_check" < /dev/null > /dev/null
#    apt install "$program_check" -y > /dev/null 2>&1
    sleep 3s
    if ! command -v "$program_check" &> /dev/null
    then
      eerror "$program_check install failed, scripts won't function wihout it, exiting"
      exit 67
    else
      edebug "$program_check now installed, continuing"
    fi
  else
      edebug "$program_check command located, continuing"
  fi
}
#
prog_check_deb () {
  prog_status=$(dpkg -s "$program_check" 2>/dev/null | grep "Status" | cut -d ' ' -f 2)
  if [[ "$prog_status" = "deinstall" ]] || [[ -z "$prog_status" ]]
  then
    ewarn "$program_check could not be found, script won't function wihout it, attempting install"
    DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null
#    apt update > /dev/null 2>&1
    DEBIAN_FRONTEND=noninteractive apt-get install -qq "$program_check" < /dev/null > /dev/null
#    apt install "$program_check" -y > /dev/null 2>&1
    sleep 1s
    prog_status=$(dpkg -s "$program_check" 2>/dev/null | grep "Status" | cut -d ' ' -f 2)
    if [[ "$prog_status" != "install" ]]
    then
      eerror "$program_check install failed, scripts won't function wihout it, exiting"
      exit 67
    else
      edebug "$program_check now installed, continuing"
    fi
  elif [[ "$prog_status" = "install" ]]; then
      edebug "$program_check command located, continuing"
  fi
}
#
# Must pass in or prepost the function with $service_name
Check_Service_ActiveState () {
  #this will return the active / inactive service state
  check=$(systemctl show -p ActiveState --value $service_name.service)
}
Check_Service_SubState () {
  #this will return the service running / exited / dead substate
  check=$(systemctl show -p SubState --value $service_name.service)
}
#
#
#+----------------------+
#+---"PROGRESS BAR"-----+
#+----------------------+
#
# "PROGRESS BAR 1"
#thanks to here https://stackoverflow.com/questions/12498304/using-bash-to-display-a-progress-indicator
#913476814 = 872mb on bytes
progress_bar () {
  sleep=$units_of_sleep
  echo "THIS MAY TAKE A WHILE, PLEASE BE PATIENT WHILE $scriptlong IS RUNNING..."
  printf "["
  # While process is running...
  while kill -0 $pid_name 2> /dev/null; do
      printf  "▓"
      sleep $sleep
#      sleep 1
  done
  printf "] done!"
  echo ""
}
#
# "PROGRESS BAR 2"
# for this all credit see answer from 'Vagiz Duseev' at https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
# Need to pass in two functions (as cant use a variable as a command in bash), get_max_progress & get_total_progress then call progress_bar2_init
# immediately after pid'ding your command you want progress from, structure goes:
# 1: put 2x functions at top of script (if using once, by each call for multiple instances), examples below
# 2: unit_of_measure=""
# 3: section=""
# 3: yourcommandhere > /dev/null 2>&1 &
# 4: yourcommandhere_pid=$!
# 5: pid_name=$yourcommandhere
# 6: progress_bar2_init
#
#get_max_progress () {
#  tail -n 1 "$working_dir/temp/$bluray_name/$bluray_name.log" | cut -d ',' -f 3
#}
#
#get_total_progress () {
#  tail -n 1 "$working_dir/temp/$bluray_name/$bluray_name.log" | cut -d ',' -f 2
#}
#
progress_bar2_init () {
  while kill -0 $pid_name 2> /dev/null; do
    progress_max=$(get_max_progress)
    progress_total=$(get_total_progress)

    #DEBUG STUFF
    #remove characters / collums for: "[", " ] " "100% " "("$progress_total " / " $progress_max " "$unit_of_measure")"
    count_standard_deduction=15 #1x"(", 1x"[", 1x")", 1x"]", 1x"100%", 1x"/", 6x " "
    edebug "deduct standard: $count_standard_deduction, should read 9"
    count_progress_max=$(echo ${#progress_max})
    edebug "count_progress_max is: $count_progress_max , should read 5"
    edebug "unit of measure is: $unit_of_measure, should read cycles"
    count_unit_of_measure=$(echo ${#unit_of_measure})
    edebug "count_unit_of_measure is: $count_unit_of_measure , should read 6"

    #SCREEN SIZING
    screen_width=$(stty size | cut -d" " -f2)
    edebug "original screen width is: $screen_width"
    screen_width_deduction=$(($count_standard_deduction + $count_unit_of_measure + $count_progress_max + $count_progress_max))
    edebug "knocking off: $screen_width_deduction , should equal $count_standard_deduction + $count_unit_of_measure + $count_progress_max + $count_progress_max"
    screen_width=$(($screen_width - $screen_width_deduction))
    edebug "final screen progress bar will be: $screen_width"

    #for use cases such as makemkv where the progress file is 'dirty' and could be text, do a test
    #if either progress_total or progress_max are NOT equal to a number enter the loop
    num_check='^[0-9]+$'
    while ! [[ $progress_total =~ $num_check ]] || ! [[ $progress_max =~ $num_check ]] ; do
      sleep .1
      progress_max=$(get_max_progress)
      progress_total=$(get_total_progress)
    done

    # Draw a progress bar
    progress_bar2 $progress_total $progress_max $unit_of_measure

    # Check if we reached 100%
    if [ $progress_total == $progress_max ]; then break; fi
    sleep 1  # Wait before redrawing
  done
# Go to the newline at the end of task
printf "\n"
}
#
progress_bar2 () {
  # Arguments: current value, max value, unit of measurement (optional)
  local __value=$1
  local __max=$2
  local __unit=${3:-""}  # if unit is not supplied, do not display it

  # Calculate percentage
  if (( $__max < 1 )); then __max=1; fi  # anti zero division protection
  local __percentage=$(( 100 - ($__max*100 - $__value*100) / $__max ))

  # Rescale the bar according to the progress bar width
  local __num_bar=$(( $__percentage * $screen_width / 100 ))

  # Draw progress bar
  printf "["
  for b in $(seq 1 $__num_bar); do printf "▓"; done
  for s in $(seq 1 $(( $screen_width - $__num_bar ))); do printf " "; done
  printf "] $__percentage%% ($__value / $__max $__unit)\r"
}
#
#
#+------------------+
#+---"IP STUFF"-----+
#+------------------+
# perhaps add this to alias just like SE answer here?
#https://unix.stackexchange.com/questions/22615/how-can-i-get-my-external-ip-address-in-a-shell-script
int_ip () {
  dig +short `hostname -f`
}

wan_ip () {
  dig @resolver4.opendns.com myip.opendns.com +short
}
#
wan_ip4 () {
  dig @resolver4.opendns.com myip.opendns.com +short -4
}
#
wan_ip6 () {
  dig @resolver1.ipv6-sandbox.opendns.com AAAA myip.opendns.com +short -6
}
#
#+------------------------+
#+---"USEFUL VARIABLES"---+
#+------------------------+
#logname=$lockname.log # Uses the script name to create the log
#stamp=$(echo "SYNC-`date +%d_%m_%Y`-`date +%H.%M.%S`")
#stamplog=$(echo "`date +%d%m%Y`-`date +%H_%M_%S`")
#dir_name="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#
#
