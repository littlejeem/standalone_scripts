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
SCRIPT_LOG="/home/pi/bin/logs/jackett_install.log"
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
  mv Jackett Jackett_$stamp
fi
tar -xvf Jackett.tar
systemctl start jackett.service
rm ~/ServerConfig.json
rm Jackett.tar
