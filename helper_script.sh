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
#+------------------------+
#+---Pushover Functions---+
#+------------------------+
pushover ()
{
  curl -s --form-string token="$backup_app_token" --form-string user="$user_token" --form-string message="$message_form" https://api.pushover.net/1/messages.json
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
# pick from 64 - 113
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file error
# exit 66 = Processing Error
# exit 67 = Required Program Missing
#
#place this in parent script immediately after the child script exits
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
