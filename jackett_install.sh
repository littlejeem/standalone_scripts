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
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
jackett_ver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | awk -F "[><]" '{print $3}')
jackett_target=$(echo $jackett_ver)
install_user=jlivin25
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
  log "downloading version $(echo $jackett_target)"
  wget -q https://github.com/Jackett/Jackett/releases/download/$jackett_target/Jackett.Binaries.LinuxAMDx64.tar.gz
  tar -xvf Jackett*
#  mv Jackett /opt/
#  if [[ $? -eq 1 ]]; then
#    log_err "moving to /opt/ failed, exiting..."
#    exit 1
#  fi
  chown $install_user:$install_user /opt/Jackett
  if [[ $? -eq 1 ]]; then
    log_err "chowning /opt/Radarr, exiting..."
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
