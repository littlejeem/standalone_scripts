#!/bin/bash
#
# taken from here https://www.htpcguides.com/install-jackett-ubuntu-15-x-for-custom-torrents-in-sonarr/
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
stamp=$(echo "`date +%d%m%Y`_`date +%H_%M_%S`")

cd /opt
systemctl stop jackett.service
mv Jackett Jackett_$stamp
tar -xvf Jackett.tar
