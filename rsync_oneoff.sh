#!/usr/bin/env bash
#
########################################
### VARIABLES / PLACEHOLDERS - RSYNC ###
########################################
log_level="1"
test="--dry-run"
flags="--progress"
switches="-avz"
log="rsync_oneoff.log"
################################
### SET VARIABLES - WHIPTAIL ###
################################
copy_operation="LOCAL --> LOCAL"
push_operation="LOCAL --> REMOTE"
pull_operation="LOCAL <-- REMOTE"
#
#
###############################
## DEFINE FUNCTIONS - RSYNC ###
###############################
user_rsync_push () {
  rsync "$test" "$switches" "$contents_from" "$remote_user"@"remote_machine":"$folder_to" >> "$log" 2>&1
}
#
user_rsync_pull () {
  rsync "$test" "$switches" "$contents_from" "$remote_user"@"remote_machine":"$folder_to" >> "$log" 2>&1
}
#
user_rsync_copy () {
  rsync "$test" "$flags" "$switches" "$source_location" "$dest_location" >> "$log" 2>&1
}
#
###################################
### DEFINE FUNCTIONS - WHIPTAIL ###
###################################
confirmation_dialog () {
TERM=ansi whiptail --title "INFO" --yesno "$display_message" 8 78
}
#
notification_dialog () {
TERM=ansi whiptail --title "INFO" --msgbox "$display_message" 8 78
}
#
input_box () {
TERM=ansi whiptail --inputbox "$display_message" 8 78 \
2>"$dir_name".tmp
}
#
source_dest_grab () {
display_message="please enter your source file or folder path"
dir_name="source_location"
input_box
source_location=`cat source_location.tmp`
display_message="please enter your destination file or folder path"
dir_name="dest_location"
input_box
dest_location=`cat dest_location.tmp`
display_message="you have chosen $operation_selected from $source_location to $dest_location, is this correct?"
confirmation_dialog
}
#
#
#+------------+#
#+-- MENU 1 --+#
#+------------+#
whiptail --title "Operation Selection" \
--radiolist "Choose operation type for the task" 20 120 3 \
"$copy_operation" "(*copy*) Transfer from folder on this machine to folder on same machine" ON \
"$push_operation" "(*push*) Transfer from folder on this machine to folder on a different machine" OFF \
"$pull_operation" "(*pull*) Transfer from folder on remote machine to this machine" OFF 2>operation_selected.tmp
#
#
#+------------------------------+#
#+-- MENU 2 - Check Selection --+#
#+------------------------------+#
operation_selected=`cat operation_selected.tmp`
#<-- debug logging
if [ "$log_level" != "1" ]
 then
 :
 else
 echo "$operation_selected" >> $log
fi
display_message="You have selected $operation_selected, is this correct?"
confirmation_dialog
result=$?
if [ "$result" == "0" ]; then
 echo "user confimed selection, deleting .tmp file and moving on" >> $log
 rm operation_selected.tmp
elif [ "$result" == "1" ]; then
 echo "user stated incorrect selection shown not, exiting" >> $log
 #<-- need to call an exit function here
fi
echo "$result" >> $log
#
#
#+---------------------------------+#
#+-- Test Selection & grab input --+#
#+---------------------------------+#
if [ "$operation_selected" == "$copy_operation" ]
 then
  display_message="running local copy"
  notification_dialog
  source_dest_grab
  result=$?
  if [ "$result" == "0" ]
   then
   echo "user confimed selection, deleting .tmp file and moving on" >> $log
   # rm source_location.tmp
   # rm dest_location.tmp
   #<-- Test if running rsync in dry run or not
   if [ "$test" == "--dry-run" ]
    then echo "running rsync in TEST mode" >> $log
    user_rsync_copy
    #<-- grab the PID of the rsync job
    rsync_user_pid=$!
    echo $rsync_user_pid >> $log
    else echo "running rsync in FULL mode" >> $log
   fi
  elif [ "$result" == "1" ]
   then
   echo "user stated selection shown not correct, exiting" >> $log
   #<-- need to call an exit function here
  fi
  echo "$result" >> $log
elif [ "$operation_selected" == "$push_operation" ]
 then
  display_message="running push"
  notification_dialog
  source_dest_grab
  result=$?
  if [ "$result" == "0" ]; then
   echo "user confimed selection, deleting .tmp file and moving on" >> $log
   rm source_location.tmp
   rm dest_location.tmp
  elif [ "$result" == "1" ]; then
   echo "user stated selection shown not correct, exiting" >> $log
  fi
elif [ "$operation_selected" == "$pull_operation" ]
 then
  display_message="running pull copy"
  notification_dialog
  display_message="source file location"
  dir_name="source_location"
  input_box
fi
#<-- debug logging
if [ "$log_level" != "1" ]
 then
 :
 else
 echo "$operation_selected" >> $log
 echo "$operation_selected"
 echo "$source_location" >> $log
 echo "$source_location"
 echo "$dest_location" >> $log
 echo "$dest_location"
 echo "$test" >> $log
 echo "$test"
fi
#
#clear
exit
