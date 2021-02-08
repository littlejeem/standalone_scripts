#!/usr/bin/env bash
#
#
#+---------------------+
#+---Logging Colours---+
#+---------------------+
#error
red='\033[0;31m'
#warning
yellow='\033[1;33m'
#success
green='\033[0;32m'
#info
brown_orange='\033[0;33m'
#others
purple='\033[0;35m'
light_blue='\033[1;34m'
#no colour
nc='\033[0m'
#
#
#+-----------------------+
#+---Logging Functions---+
#+-----------------------+
tty -s && function log()     {     echo "$(date +%b"  "%-d" "%T)" " "INFO: "$@"; }
tty -s && function log_deb() {     echo "$(date +%b"  "%-d" "%T)" DEBUG: "$@"; }
tty -s && function log_err() { >&2 echo "$(date +%b"  "%-d" "%T)" ERROR: "$@"; }
tty -s || function log()     { logger -t INFO $(basename $0) "$@"; }
tty -s || function log_deb() { logger -t DEBUG $(basename $0) "$@"; }
tty -s || function log_err() { logger -t ERROR $(basename $0) -p user.err "$@"; }
#
#
#+-------------------------------+
#+---"Check if already runnng"---+
#+-------------------------------+
check_running () {
  temp_dir="$lockname"
  if [[ -d /var/"$lockname" ]]; then
    while [[ -d /var/"$lockname" ]]; do
      log "previous script still running"
      sleep 2m; done
      #  else
      log "no previously running script detected"
  fi
  log "Attempting to lock script"
  mkdir /tmp/"$lockname"
  if [[ $? = 0 ]]; then
    log_deb "temp dir is set as: /tmp/$lockname"
    log "temp directory set successfully, script locked"
  else
    log_err "setting temp directory unsuccessfull, exiting"
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
    log "$scriptlong exited gracefully"
  elif [ "$reply" = 64 ]]; then
    log_err "Exit code: $reply received"
    log_deb "Script $scriptlong exited with 'Variable' error"
  elif [ "$reply" = 65 ]]; then
    log_err "Exit code: $reply received"
    log_deb "Script $scriptlong exited with 'sourcing script or config' error"
  elif [ "$reply" = 65 ]]; then
    log_err "Exit code: $reply received"
    log_deb "Script $scriptlong exited with 'Processing' error"
  elif [ "$reply" = 66 ]]; then
    log_err "Exit code: $reply received"
    log_deb "Script $scriptlong exited with 'Missing Program' error"
  elif [ "$reply" = 1 ]]; then
    log_err "Exit code: $reply received"
    log_deb "Script $scriptlong exited with generic bash error"
  fi
}
#
#
#+----------------------+
#+---"Variable Tests"---+
#+----------------------+
fatal_missing_var () {
 if [ -z "${JAIL_FATAL}" ]; then
  log_err "Failed to find: $JAIL_FATAL, JAIL_FATAL is unset or set to the empty string, script cannot continue. Exiting!"
  rm -r /tmp/"$lockname"
  exit 64
 else
  log "variable found, using: $JAIL_FATAL"
 fi
}
#
debug_missing_var () {
 if [ -z "${JAIL_DEBUG}" ]; then
  log_deb "JAIL_DEBUG $JAIL_DEBUG is unset or set to the empty string, may cause issues"
 else
  log "variable found, using: $JAIL_DEBUG"
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
