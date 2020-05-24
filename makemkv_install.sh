#!/bin/bash
# a script to automate installation of MakeMKV
#
#
topdir="/home/jlivin25"
assigned_user="jlivin25"
#+-----------------------------------------------+
#+----check running as root before continuing----+
#+-----------------------------------------------+
if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi
#
#
#+--------------------------------+
#+----FInd the current version----+
#+--------------------------------+
urlcontent=$(wget https://www.makemkv.com/forum/viewtopic.php?f=3&t=224 -q -O -)
version_grab=$(echo "$urlcontent" | grep -o -P '(?<=<title>).*(?=</title>)')
version=${version_grab:8:6}
#
#
#+-------------------------+
#+----Start Main Script----+
#+-------------------------+
cd ~/
sudo -u $assigned_user mkdir -p "$topdir"/Downloads
cd "$topdir"/Downloads
wget https://www.makemkv.com/download/makemkv-bin-"$version".tar.gz
wget https://www.makemkv.com/download/makemkv-oss-"$version".tar.gz
mkdir -p makemkv-bin
mkdir -p makemkv-oss
tar xf makemkv-bin-*.tar.gz -C makemkv-bin --strip-components 1
tar xf makemkv-oss-*.tar.gz -C makemkv-oss --strip-components 1
rm makemkv-*-*.tar.gz
#
#
#+-------------------------+
#+---Sort out ownerships---+
#+-------------------------+
chown -R "$assigned_user":"$assigned_user" "$topdir"/Downloads
chmod -R 766 "$topdir"/Downloads
#
#
#+---------------+
#+---build OSS---+
#+---------------+
cd "$topdir"/Downloads/makemkv-oss
sudo -u $assigned_user ./configure
sudo -u $assigned_user make
sudo make install
#
#
#+---------------+
#+---build BIN---+
#+---------------+
cd "$topdir"/Downloads/makemkv-bin
sudo -u $assigned_user make
sudo make install
