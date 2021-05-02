#!/bin/bash
#
#+-------------------+
#+---"VERSION 2.0"---+
#+-------------------+
#
# taken from here https://www.htpcguides.com/install-jackett-ubuntu-15-x-for-custom-torrents-in-sonarr/
#+------------------+
#+---"Exit Codes"---+
#+------------------+
# pick from 64 - 113 (https://tldp.org/LDP/abs/html/exitcodes.html#FTN.AEN23647)
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file error
# exit 66 = Processing Error
# exit 67 = Required Program Missing
#
#
### verbosity levels
#silent_lvl=0
#crt_lvl=1
#err_lvl=2
#wrn_lvl=3
#ntf_lvl=4
#inf_lvl=5
#dbg_lvl=6
#
#+---------------------------+
#+---Set Version & Logging---+
#+---------------------------+
version="2.1"
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
verbosity=6
#
#+---------------------------------------------+
#+---check running as root before continuing---+
#+---------------------------------------------+
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
jackett_ver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | awk -F "[><]" '{print $3}' | cut -d \/ -f 2)
jackett_target=$(echo $jackett_ver)
backup_name=$(echo Jackett_$(date +%d.%m.%y_%H:%M))
#
#
#+-------------------+
#+---Set functions---+
#+-------------------+
function helpFunction () {
   echo ""
   echo "Usage: $0 -u ####"
   echo "Usage: $0"
   echo -e "\t Running the script with no flags causes default behaviour"
   echo -e "\t-u Use this flag to specify a user to install jackett under"
   exit 1 # Exit script after printing help
}
#
#
#+-----------------------+
#+---Set up user flags---+
#+-----------------------+
while getopts u:h flag
do
    case "${flag}" in
        u) user_install=${OPTARG};;
        h) helpFunction;;
        ?) helpFunction;;
    esac
done
#
#
#+-------------------------+
#+---Configure user name---+
#+-------------------------+
if [[ $user_install == "" ]]; then
  install_user=jlivin25
else
  install_user=$(echo $user_install)
fi
#
#
#+-------------------+
#+---Source helper---+
#+-------------------+
source /usr/local/bin/helper_script.sh
#
#
#+-------------------------+
#+---"Start main script"---+
#+-------------------------+
enotify "$scriptlong started"
exit 0
if [ -d "/opt/Jackett" ]; then
  edebug "Jackett install detected, attempting update"
  cd /opt
  wget -q https://github.com/Jackett/Jackett/releases/download/$jackett_target/Jackett.Binaries.LinuxAMDx64.tar.gz
  edebug "Attempting to stop the service"
  systemctl stop jackett.service
  if [[ $? -ne 0 ]]; then
    eerror "stopping service failed, exiting..."
    exit 66
  else
    edebug "Stopped service file successfully"
  fi
  if [ -f /home/$install_user/.config/Jackett/ServerConfig.json ]; then
    edebug "Config file found, making backup"
    cp /home/$install_user/.config/Jackett/ServerConfig.json /home/$install_user/.config/ServerConfig.json
    edebug "backing up old files"
    mv Jackett backup: "$backup_name"
  else
    edebug "No config file found, this might be an error"
  fi
  edebug "extracting .tar file"
  tar -xvf Jackett*.tar.gz > /dev/null
  if [[ $? -ne 0 ]]; then
    eerror "extracting .tar failed, exiting"
    exit 66
  fi
  edebug "setting install directory permissions"
  chown $install_user:$install_user /opt/Jackett
  if [[ $? -eq 1 ]]; then
    eerror "chowning /opt/Radarr failed, exiting..."
    exit 66
  fi
  edebug "Starting jackett.service"
  systemctl start jackett.service
  if [[ $? -ne 0 ]]; then
    eerror "Starting jackett.service failed"
    exit 66
  else
    edebug "starting jackett.service succeded"
  fi
  edebug "deleting backups"
  rm /home/$install_user/.config/ServerConfig.json
  rm Jackett*.tar.gz
else
  edebug "No Jackett install detected, attempting install"
  cd /opt
  edebug "downloading version $(echo $jackett_target)"
  wget -q https://github.com/Jackett/Jackett/releases/download/$jackett_target/Jackett.Binaries.LinuxAMDx64.tar.gz
  tar -xvf Jackett*.tar.gz > /dev/null
  edebug "setting install directory permissions"
  chown $install_user:$install_user /opt/Jackett
  if [[ $? -eq 1 ]]; then
    eerror "chowning /opt/Radarr failed, exiting..."
    exit 66
  fi
  edebug "creating .service file"
  if [ -f "/etc/systemd/system/jackett.service" ]; then
cat > /etc/systemd/system/jackett.service <<EOF
[Unit]
Description=Jackett Daemon
After=network.target

[Service]
SyslogIdentifier=jackett
Restart=always
RestartSec=5
Type=simple
User=$install_user
Group=$install_user
WorkingDirectory=/opt/Jackett
ExecStart=/opt/Jackett/jackett --NoRestart
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
EOF
  else
    eerror "Jackett.service file located, exiting"
    exit 65
  fi
  if [[ $? -eq 1 ]]; then
    eerror "creating .service file failed, exiting..."
    exit 65
  else
    edebug "created .service file"
  fi
  edebug "starting service"
  systemctl daemon-reload
  systemctl start jackett.service
  if [[ $? -ne 0 ]]; then
    eerror "starting service failed, exiting..."
    exit 66
  else
    edebug "Started service file successfully"
  fi
  edebug "cleaning up install files"
  rm /opt/Jackett.Binaries*.tar.gz
fi
enotify "$scriptlong completed"
exit 0
