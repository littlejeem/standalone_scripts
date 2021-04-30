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
version="2.0"
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
jackett_ver=$(jackett_ver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | awk -F "[><]" '{print $3}' | cut -d \/ -f 2)
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
source /home/$install_user/bin/standalone_scripts/helper_script.sh
#
#
#+-------------------------+
#+---"Start main script"---+
#+-------------------------+
if [ -d "/opt/Jackett" ]; then
  einfo "Jackett install detected, attempting update"
  cd /opt
  wget -q https://github.com/Jackett/Jackett/releases/download/$jackett_target/Jackett.Binaries.LinuxAMDx64.tar.gz
  einfo "Attempting to stop the service"
  systemctl stop jackett.service
  if [[ $? -ne 0 ]]; then
    eerror "stopping service failed, exiting..."
    exit 1
  else
    einfo "Stopped service file successfully"
  fi
  if [ -f /home/$install_user/.config/Jackett/ServerConfig.json ]; then
    einfo "Config file found, making backup"
    cp /home/$install_user/.config/Jackett/ServerConfig.json /home/$install_user/.config/ServerConfig.json
    einfo "backing up old files"
    mv Jackett $backup_name
  else
    edebug "No config file found, this might be an error"
  fi
  tar -xvf Jackett*.tar.gz
  if [[ $? -ne 0 ]]; then
    eerror "extracting Jackett failed, exiting"
    exit 1
  fi
  einfo "setting install directory permissions"
  chown $install_user:$install_user /opt/Jackett
  if [[ $? -eq 1 ]]; then
    eerror "chowning /opt/Radarr failed, exiting..."
    exit 1
  fi
  einfo "Starting jackett.service"
  systemctl start jackett.service
  if [[ $? -ne 0 ]]; then
    eerror "Starting jackett.service failed"
    exit 1
  else
    einfo "starting jackett.service succeded"
  fi
  einfo "deleting backups"
  rm /home/$install_user/.config/ServerConfig.json
  rm Jackett*.tar.gz
else
  einfo "No Jackett install detected, attempting install"
  cd /opt
  einfo "downloading version $(echo $jackett_target)"
  wget -q https://github.com/Jackett/Jackett/releases/download/$jackett_target/Jackett.Binaries.LinuxAMDx64.tar.gz
  tar -xvf Jackett*.tar.gz
#  mv Jackett /opt/
#  if [[ $? -eq 1 ]]; then
#    eerror "moving to /opt/ failed, exiting..."
#    exit 1
#  fi
  einfo "setting install directory permissions"
  chown $install_user:$install_user /opt/Jackett
  if [[ $? -eq 1 ]]; then
    eerror "chowning /opt/Radarr failed, exiting..."
    exit 1
  fi
  einfo "creating .service file"
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
    exit 1
  fi
  if [[ $? -eq 1 ]]; then
    eerror "creating .service file failed, exiting..."
    exit 1
  else
    einfo "created .service file"
  fi
  einfo "starting service"
  systemctl daemon-reload
  systemctl start jackett.service
  if [[ $? -ne 0 ]]; then
    eerror "starting service failed, exiting..."
    exit 1
  else
    einfo "Started service file successfully"
  fi
  einfo "cleaning up install files"
  rm /opt/Jackett.Binaries*.tar.gz
fi
