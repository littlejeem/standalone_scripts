#!/bin/bash
#
# taken from here https://www.htpcguides.com/install-jackett-ubuntu-15-x-for-custom-torrents-in-sonarr/
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
SCRIPTENTRY
sctipt_log="/home/pi/bin/logs/jackett_install.log"
stamp=$(Timestamp)
#
#
cd /opt
target https://github.com/Jackett/Jackett/releases/download/v0.16.1724/Jackett.Binaries.LinuxAMDx64.tar.gz
jackettver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | awk -F "[><]" '{print $3}')
wget -q https://github.com/Jackett/Jackett/releases/download/$jackettver/Jackett.Binaries.LinuxAMDx64.tar.gz
cp ~/.config/Jackett/ServerConfig.json ~/ServerConfig.json
systemctl stop jackett.service
#
if [ -d "Jackett" ]; then
  ENTRY
  mv Jackett Jackett_$stamp
  EXIT
fi
tar -xvf Jackett.tar
INFO
systemctl start jackett.service
INFO
rm ~/ServerConfig.json
INFO
rm Jackett.tar
INFO
#
#
SCRIPTEXIT
