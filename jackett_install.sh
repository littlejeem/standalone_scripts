#!/bin/bash
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
#+-------------------+
#+---Source helper---+
#+-------------------+
source ./helper_script.sh
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
SCRIPT_LOG="/home/pi/bin/logs/jackett_install.log"
stamp=$(Timestamp)
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
#
#
jackett_ver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | awk -F "[><]" '{print $3}')
jackett_target=$(echo $jackettver)
if [ -d "/opt/Jackett" ]; then
  log "Jackett install detected, attempting update"
  cd /opt
  wget -q https://github.com/Jackett/Jackett/releases/download/$jackett_target/Jackett.Binaries.LinuxAMDx64.tar.gz
  cp ~/.config/Jackett/ServerConfig.json ~/ServerConfig.json
  systemctl stop jackett.service
  #
  if [ -d "Jackett" ]; then
    mv Jackett Jackett_$stamp
  fi
  tar -xvf Jackett.tar
  systemctl start jackett.service
  rm ~/ServerConfig.json
  rm Jackett.tar
else
  log "No Jackett install detected, attempting install"
  cd /opt
  log "downloading version $jackett_target"
  wget -q https://github.com/Jackett/Jackett/releases/download/$jackett_target/Jackett.Binaries.LinuxAMDx64.tar.gz
  tar -xvf Jackett*
#  mv Jackett /opt/
#  if [[ $? -eq 1 ]]; then
#    log_err "moving to /opt/ failed, exiting..."
#    exit 1
#  fi
  chmod $USER:$USER /opt/Jackett
  if [[ $? -eq 1 ]]; then
    log_err "chowning /opt/Radarr, exiting..."
    exit 1
  fi
  log "creating .service file"
  cat > /etc/systemd/system/jackett.service <<-EOF
  [Unit]
  Description=Jackett Daemon
  After=network.target

  [Service]
  SyslogIdentifier=jackett
  Restart=always
  RestartSec=5
  Type=simple
  User=$USER
  Group=$USER
  WorkingDirectory=/opt/Jackett
  ExecStart=/opt/Jackett/jackett --NoRestart
  TimeoutStopSec=20

  [Install]
  WantedBy=multi-user.target
  EOF
  if [[ $? -eq 1 ]]; then
    log_err "creating .service file failed, exiting..."
    exit 1
  else
    log "creating .service file"
  fi
  log "starting service"
  systemctl daemon-reload
  systemctl start jacket.service
  if [[ $? -ne 0 ]]; then
    log_err "starting service failed, exiting..."
    exit 1
  else
    log "Started service file successfully"
  fi


fi
