#!/usr/bin/env bash
#
#
######################################################################
### INFORMATION
### Your script must define the following variables:
###
### sctipt_log --> to use the logging ###
### $backup_app_token, $user_token & $message_form --> to use Pushover
######################################################################
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
tty -s && function log()     {     echo $(date +%a)    $(date +%d) $(date +%T): INFO "$@"; }
tty -s && function log_deb() {     echo $(date +%a)    $(date +%d) $(date +%T): DEBUG "$@"; }
tty -s && function log_err() { >&2 echo $(date +%a)    $(date +%d) $(date +%T): ERROR "$@"; }
tty -s || function log()     { logger -t INFO $(basename $0) "$@"; }
tty -s || function log_deb() { logger -t DEBUG $(basename $0) "$@"; }
tty -s || function log_err() { logger -t ERROR $(basename $0) -p user.err "$@"; }
#
#
#+------------------------+
#+---Pushover Functions---+
#+------------------------+
function Pushover ()
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
function Timestamp ()
{
  echo "$(date +%d/%m/%Y) - $(date +%H:%M:%S) - $1"
}
#
#
