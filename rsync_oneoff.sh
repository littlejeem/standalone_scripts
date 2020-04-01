#!/usr/bin/env bash
#
################################
### VARIABLES / PLACEHOLDERS ###
################################
test="--dry-run"
switches="--progress -avz"
contents_from="/media/Data_1/Videos/SD_Films/" #folder to copy contents from
folder_to="/mnt/usbstorage/movies" #folder into which copied contents go
remote_user=""
remote_machine="" #remote IP
log="/home/jlivin25/bin/scriptlogs/sdmov.log"
#
##############################
## DEFINE FUNCTION COMMAND ###
##############################
user_rsync () {
  nohup rsync "$test" "$switches" "$contents_from" "$remote_user"@"remote_machine":"$folder_to" > "$log" 2>&1
  #nohup rsync --dry-run --progress -avz /media/Data_1/Videos/SD_Films/ pi@192.168.0.18:/mnt/usbstorage/movies > /home/jlivin25/bin/scriptlogs/sdmov.log 2>&1
}
#
###################
### RUN COMMAND ###
###################
user_rsync
#
