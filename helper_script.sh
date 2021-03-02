#!/usr/bin/env bash
#
#
#+---------------------+
#+---Logging Colours---+
#+---------------------+
colblk='\033[0;30m' # Black - Regular
colred='\033[0;31m' # Red
colgrn='\033[0;32m' # Green
colylw='\033[0;33m' # Yellow
colpur='\033[0;35m' # Purple
colrst='\033[0m'    # Text Reset
#
#
#+-----------------------+
#+---Logging Functions---+
#+-----------------------+
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
tty -s && esilent () { verb_lvl=$silent_lvl elog "$@"; }
tty -s && enotify () { verb_lvl=$ntf_lvl elog "${colwht}NOTICE${colrst} - $*"; }
tty -s && eok ()    { verb_lvl=$ntf_lvl elog "${colrst}SUCCESS${colrst} - $*"; }
tty -s && ewarn ()  { verb_lvl=$wrn_lvl elog "${colylw}WARNING${colrst} - $*"; }
tty -s && einfo ()  { verb_lvl=$inf_lvl elog "${colwht}INFO${colrst} ---- $*"; }
tty -s && edebug () { verb_lvl=$dbg_lvl elog "${colgrn}DEBUG${colrst} --- $*"; }
tty -s && eerror () { verb_lvl=$err_lvl elog "${colred}ERROR${colrst} --- $*"; }
tty -s && ecrit ()  { verb_lvl=$crt_lvl elog "${colpur}FATAL${colrst} --- $*"; }
tty -s && edumpvar () { for var in "$@" ; do edebug "$var=${!var}" ; done }
# syslog versions
tty -s || esilent () { verb_lvl=$silent_lvl slog "["$(basename $0)"]" "$@" ;}
tty -s || enotify () { verb_lvl=$ntf_lvl slog "["$(basename $0)"]" "NOTICE - $*"; }
tty -s || eok ()    { verb_lvl=$ntf_lvl slog "["$(basename $0)"]" "SUCCESS - $*"; }
tty -s || ewarn ()  { verb_lvl=$wrn_lvl slog "["$(basename $0)"]" "WARNING - $*"; }
tty -s || einfo ()  { verb_lvl=$inf_lvl slog "["$(basename $0)"]" "INFO ---- $*"; }
tty -s || edebug () { verb_lvl=$dbg_lvl slog "["$(basename $0)"]" "DEBUG --- $*"; }
tty -s || eerror () { verb_lvl=$err_lvl slog "["$(basename $0)"]" "ERROR --- $*"; }
tty -s || ecrit ()  { verb_lvl=$crt_lvl slog "["$(basename $0)"]" "FATAL --- $*"; }
tty -s || edumpvar () { for var in "$@" ; do edebug "$var=${!var}" ; done }
# Error log function for terminal
elog() {
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
#+-------------------------------+
#+---"Check if already runnng"---+
#+-------------------------------+
check_running () {
  if [[ -d /var/"$lockname" ]]; then
    while [[ -d /var/"$lockname" ]]; do
      einfo "previous script still running"
      sleep 2m; done
      #  else
      einfo "no previously running script detected"
  fi
  einfo "Attempting to lock script"
  mkdir /tmp/"$lockname"
  if [[ $? = 0 ]]; then
    edebug "temp dir is set as: /tmp/$lockname"
    einfo "temp directory set successfully, script locked"
  else
    eerror "setting temp directory unsuccessfull, exiting"
    exit 65
  fi
}
#+------------------------+
#+---Pushover Functions---+
#+------------------------+
pushover ()
{
  curl -s --form-string token="$backup_app_token" --form-string user="$user_token" --form-string message="$message_form" https://api.pushover.net/1/messages.json
}
#
#
#+----------------------+
#+---"Kodi Functions"---+
#+----------------------+
update_videolibrary () {
  curl --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodi_VIDEO_assembly
}
#
update_musiclibrary () {
  curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly
}
#
clean_videolibrary () {
  curl --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodi_VIDEO_assembly
}
#
clean_musiclibrary () {
  curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly
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
#+---"Exit Codes"---+
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
#+----------------------+
#+---"Variable Tests"---+
#+----------------------+
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
#+------------------------+
#+---"Useful Variables"---+
#+------------------------+
#logname=$lockname.log # Uses the script name to create the log
#stamp=$(echo "SYNC-`date +%d_%m_%Y`-`date +%H.%M.%S`")
#stamplog=$(echo "`date +%d%m%Y`-`date +%H_%M_%S`")
#dir_name="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#
#
