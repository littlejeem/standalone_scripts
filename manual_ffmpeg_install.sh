#!/bin/bash
#
#
############################################################
### A script to automate manual install of ffmpeg        ###
### https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu ###
############################################################
#
#
#############################
### CHECK RUNNING AS ROOT ###
#############################
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
else
#
#
####################################
### GET AND INSTALL DEPENDANCIES ###
####################################
apt update -qq && apt -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
  git-core \
  libass-dev \
  libfreetype6-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  pkg-config \
  texinfo \
  wget \
  zlib1g-dev
####################################################
### CREATE NECESSARY DIRECTORIES IF NOT EXISTING ###
####################################################
mkdir -p ~/ffmpeg_sources ~/bin
#
#
#####################################
### INSTALL THIRD-PARTY LIBRARIES ###
#####################################
sudo apt-get install nasm
sudo apt-get install yasm
sudo apt-get install libx264-dev
sudo apt-get install libx265-dev libnuma-dev
sudo apt-get install libvpx-dev
sudo apt-get install libfdk-aac-dev
sudo apt-get install libmp3lame-dev
#
#
############################################################
### CONFIGURE & INSTALL FFMPEG TO INLCUDE EXTRA PACKAGES ###
############################################################
cd ~/ffmpeg_sources && \
wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
tar xjvf ffmpeg-snapshot.tar.bz2 && \
cd ffmpeg && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree && \
PATH="$HOME/bin:$PATH" make -j2 && \
make -j2 install && \
hash -r
fi
echo "now exit and relogin entering 'source ~/.profile'"
exit 0
