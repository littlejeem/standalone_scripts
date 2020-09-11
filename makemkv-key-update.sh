#!/bin/bash
#
#
###################################################################
### "A script to automatically update the key for MakeMKV beta" ###
###################################################################
file_loc=/home/jlivin25/.MakeMKV/settings.conf
url_content=$(wget https://www.makemkv.com/forum/viewtopic.php?t=1053 -q -O -)
key=$(echo "$url_content" | grep -o -P '(?<=<code>).*(?=</code>)')
echo "$key"
keyinsert=('"'$key'"')
if test -f "$file_loc"
then
  echo "$file_loc exists"
  if [ -s "$_file" ]
  then
  	echo "$file_loc not empty so inserting key"
    sed -i 's/".*"/\'$keyinsert'/' $file_loc
  else
  	echo "$file_loc is empty, inserting text"
    echo 'app_Key = ""' > $file_loc
    sed -i 's/".*"/\'$keyinsert'/' $file_loc
  fi
else
  echo "$file_loc doesn't exist, creating it"
  touch $file_loc
  echo "inserting appKey variable"
  echo 'app_Key = ""' > $file_loc
  echo "inserting key"
  sed -i 's/".*"/\'$keyinsert'/' $file_loc
fi
