#!/bin/bash

# this script is to automatically convert a folder of video files
# You need to change SRC -- Source folder and DEST -- Destination folder
VERSION="0.8"
SRC="/media/Data_1/Videos/TV_Shows/Chernobyl/Season 1"
DEST="/home/jlivin25/Videos"
DEST_EXT="mp4"
HANDBRAKE_CLI=HandBrakeCLI
PRESET="Very Fast 1080p30"
#HandBrakeCLI -i /media/Data_1/Videos/TV_Shows/Chernobyl/Season\ 1/S01E01\ -\ 1-23-45.mkv -o /home/jlivin25/Videos/S01E01\ -\ 1-23-45.mkv --preset "Very Fast 1080p30"
#
#
for FILE in "$SRC"/*
do
 filename=$(basename "$FILE")
 extension=${filename##*.}
 filename=${filename%.*}
$HANDBRAKE_CLI -i "$FILE" -o "$DEST/$filename.$DEST_EXT" "$PRESET"
done
