#!/bin/bash
# a script to automate installation of MakeMKV
#
#
topdir="/home/jlivin25"
cd ~/
mkdir -p "$topdir"/Downloads
cd "$topdir"/Downloads
wget https://www.makemkv.com/download/makemkv-bin-1.15.1.tar.gz
wget https://www.makemkv.com/download/makemkv-oss-1.15.1.tar.gz
mkdir -p makemkv-bin
mkdir -p makemkv-oss
tar xf makemkv-bin-*.tar.gz -C makemkv-bin --strip-components 1
tar xf makemkv-oss-*.tar.gz -C makemkv-oss --strip-components 1
rm makemkv-*-*.tar.gz
#
#
#+---build OSS---+
cd makemkv-oss
./configure
make
sudo make install
#
#
#+---build BIN---+
cd
make
sudo make install
