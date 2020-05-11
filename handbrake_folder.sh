#!/bin/bash

# this script is to automatically convert a folder of video files
# You need to change SRC -- Source folder and DEST -- Destination folder
VERSION="1.0"
<<<<<<< HEAD
SRC="/media/Data_1/Videos/TV_Shows/Chernobyl/Season 1"
DEST="/home/jlivin25/Videos/conversions/Chernobyl"
DEST_EXT="mp4"
=======
SRC="" #<--- include spaces but no trailing slash
DEST="" #<--- include spaces but no trailing slash
DEST_EXT="mp4" #<--- .mp4 extension by default
>>>>>>> 18b6cf0007c3e47e9d70c435fed010d478690d5f
HANDBRAKE_CLI=HandBrakeCLI
PRESET="Very Fast 1080p30"
#
#
for FILE in "$SRC"/*
do
 filename=$(basename "$FILE")
 extension=${filename##*.}
 filename=${filename%.*}
$HANDBRAKE_CLI -i "$FILE" -o "$DEST/$filename.$DEST_EXT" "$PRESET"
done
