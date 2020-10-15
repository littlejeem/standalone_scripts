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
SCRIPT_LOG="/home/pi/bin/SystemOut.log"
touch $SCRIPT_LOG
#
#
#function Timestamp ()
#{
#  echo "$(date +%d/%m/%Y) - $(date +%H:%M:%S) - $1"
#}
#
#
#+-----------------------+
#+---Logging Functions---+
#+-----------------------+
SCRIPTENTRY ()
{
 timeAndDate=$(date)
 script_name="demo2.sh"
 script_name="${script_name%.*}"
 echo "[$timeAndDate] [DEBUG] > $script_name $FUNCNAME" >> $SCRIPT_LOG
}
#
SCRIPTEXIT ()
{
 script_name="demo2.sh"
 script_name="${script_name%.*}"
 echo "[$timeAndDate] [DEBUG] < $script_name $FUNCNAME" >> $SCRIPT_LOG
}
#
ENTRY ()
{
local cfn="${FUNCNAME[1]}"
#cfn="${FUNCNAME[1]}"
 timeAndDate=$(date)
 echo "[$timeAndDate] [DEBUG] > $cfn $FUNCNAME" >> $SCRIPT_LOG
}
#
EXIT ()
{
local cfn="${FUNCNAME[1]}"
# cfn="${FUNCNAME[1]}"
 timeAndDate=$(date)
 echo "[$timeAndDate] [DEBUG] < $cfn $FUNCNAME" >> $SCRIPT_LOG
}
#
INFO ()
{
 local function_name="${FUNCNAME[1]}"
   local msg="$1"
    timeAndDate=$(date)
    echo "[$timeAndDate] [INFO]  $msg" >> $SCRIPT_LOG
}
#
DEBUG ()
{
 local function_name="${FUNCNAME[1]}"
   local msg="$1"
    timeAndDate=$(date)
 echo "[$timeAndDate] [DEBUG]  $msg" >> $SCRIPT_LOG
}
#
ERROR ()
{
 local function_name="${FUNCNAME[1]}"
   local msg="$1"
    timeAndDate=$(date)
    echo "[$timeAndDate] [ERROR]  $msg" >> $SCRIPT_LOG
}
#
#
#+------------------------+
#+---Pushover Functions---+
#+------------------------+
#
