#!/bin/bash
#
#
#############################################################
### A script to automatically update the key MakeMKV beta ###
#############################################################
file_loc=/home/jlivin25/.MakeMKV/settings.conf
url_content=$(wget https://www.makemkv.com/forum/viewtopic.php?t=1053 -q -O -)
key=$(echo "$url_content" | grep -o -P '(?<=<code>).*(?=</code>)')
echo "$key"
keyinsert=('"'$key'"')
touch $file_loc
sed -i 's/".*"/\'$keyinsert'/' $file_loc
