#!/bin/bash
#
#+-------------------+
#+---"VERSION 2.0"---+
#+-------------------+
#
# taken from here https://www.htpcguides.com/install-jackett-ubuntu-15-x-for-custom-torrents-in-sonarr/
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
jackett_ver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | awk -F "[><]" '{print $3}')
jackett_target=$(echo $jackett_ver)
backup_name=$(echo Jackett_$(date +%d.%m.%y_%H:%M))
#
#
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
  log "Jackett install detected, attempting update"
  cd /opt
  wget -q https://github.com/Jackett/Jackett/releases/download/$jackett_target/Jackett.Binaries.LinuxAMDx64.tar.gz
  log "Attempting to stop the service"
  systemctl stop jackett.service
  if [[ $? -ne 0 ]]; then
    log_err "stopping service failed, exiting..."
    exit 1
  else
    log "Stopped service file successfully"
  fi
  if [ -f /home/$install_user/.config/Jackett/ServerConfig.json ]; then
    log "Config file found, making backup"
    cp /home/$install_user/.config/Jackett/ServerConfig.json /home/$install_user/.config/ServerConfig.json
    log "backing up old files"
    mv Jackett $backup_name
  else
    log_deb "No config file found, this might be an error"
  fi
  tar -xvf Jackett*.tar.gz
  if [[ $? -ne 0 ]]; then
    log_err "extracting Jackett failed, exiting"
    exit 1
  fi
  log "setting install directory permissions"
  chown $install_user:$install_user /opt/Jackett
  if [[ $? -eq 1 ]]; then
    log_err "chowning /opt/Radarr failed, exiting..."
    exit 1
  fi
  log "Starting jackett.service"
  systemctl start jackett.service
  if [[ $? -ne 0 ]]; then
    log_err "Starting jackett.service failed"
    exit 1
  else
    log "starting jackett.service succeded"
  fi
  log "deleting backups"
  rm /home/$install_user/.config/ServerConfig.json
  rm Jackett*.tar.gz
else
  log "No Jackett install detected, attempting install"
  cd /opt
  log "downloading version $(echo $jackett_target)"
  wget -q https://github.com/Jackett/Jackett/releases/download/$jackett_target/Jackett.Binaries.LinuxAMDx64.tar.gz
  tar -xvf Jackett*.tar.gz
#  mv Jackett /opt/
#  if [[ $? -eq 1 ]]; then
#    log_err "moving to /opt/ failed, exiting..."
#    exit 1
#  fi
  log "setting install directory permissions"
  chown $install_user:$install_user /opt/Jackett
  if [[ $? -eq 1 ]]; then
    log_err "chowning /opt/Radarr failed, exiting..."
    exit 1
  fi
  log "creating .service file"
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
    log_err "Jackett.service file located, exiting"
    exit 1
  fi
  if [[ $? -eq 1 ]]; then
    log_err "creating .service file failed, exiting..."
    exit 1
  else
    log "created .service file"
  fi
  log "starting service"
  systemctl daemon-reload
  systemctl start jackett.service
  if [[ $? -ne 0 ]]; then
    log_err "starting service failed, exiting..."
    exit 1
  else
    log "Started service file successfully"
  fi
  log "cleaning up install files"
  rm /opt/Jackett.Binaries*.tar.gz
fi
