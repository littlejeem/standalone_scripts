#!/bin/bash

# this script is to automatically convert a folder of video files
# You need to change SRC -- Source folder and DEST -- Destination folder
VERSION="1.1"
SRC="" #<--- include spaces but no trailing slash
DEST="" #<--- include spaces but no trailing slash
DEST_EXT="mp4" #<--- .mp4 extension by default
HANDBRAKE_CLI=HandBrakeCLI
PRESET="Very Fast 1080p30"
#
#
for FILE in "$SRC"/*
do
 filename=$(basename "$FILE")
 extension=${filename##*.}
 filename=${filename%.*}
$HANDBRAKE_CLI -i "$FILE" -o "$DEST/$filename.$DEST_EXT" -Z "$PRESET"
done
