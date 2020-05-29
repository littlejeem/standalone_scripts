#!/usr/bin/env bash
# Purpose: batch image resizer
# Source: https://guides.wp-bullet.com
# Author: Mike
#
# absolute path to image folder
FOLDER="/media/Data_1/KODI_Slideshow"
#
# max width
WIDTH=540
#
# max height
HEIGHT=300
#
#
#+----------------------+
#+---Code Explanation---+
#+----------------------+
#Find Source           FileSearch Escape   nonCASEsens filetype1 OR  nonCASEsens filetype2 Escape Executecommand convert filename Detail   ResizePic  Resizetowhat(% or PIXxPIX) filename end-exec
#find ${source_folder} -type f    \(       -iname      \*.jpg    -o  -iname      \*.png    \)     -exec          convert \{}      -verbose -resize    25%\>                      \{}      \;
#
#
#+----------------------+
#+---Two Type Convert---+
#+----------------------+
#resize png or jpg to % of original using imagemagick
find ./ -type f \( -iname \*.jpg -o -iname \*.png \) -exec convert \{} -verbose -resize 25%\> \{} \;
#
#
#+----------------------+
#+---One Type Convert---+
#+----------------------+
#resize png to either height or width, keeps proportions using imagemagick
#find ./ -type f \( -iname \*.png \) -exec convert \{} -verbose -resize 25%\> \{} \;
#resize jpg only to either height or width, keeps proportions using imagemagick
#find ./ -type f \( -iname \*.jpg \) -exec convert \{} -verbose -resize 25%\> \{} \;
