#!/bin/sh
#
# thanks to https://github.com/tknr/cuesplit
# frontend for:            cuetools, shntool, mp3splt
# optional dependencies:    flac, mac, wavpack, ttaenc
# v1.3 sen
#
#+--------------------------------------+
#+---"Exit Codes & Logging Verbosity"---+
#+--------------------------------------+
# pick from 64 - 113 (https://tldp.org/LDP/abs/html/exitcodes.html#FTN.AEN23647)
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file/folder error
# exit 66 = Processing Error
# exit 67 = Required Program Missing
#
#verbosity levels
#silent_lvl=0
#crt_lvl=1
#err_lvl=2
#wrn_lvl=3
#ntf_lvl=4
#inf_lvl=5
#dbg_lvl=6
#
#
#+-------------------+
#+---"Main Script"---+
#+-------------------+
verbosity=2
#
SDIR=`pwd`

if [ "$1" = "" ]
  then
    DIR=$SDIR
else
    case $1 in
        -h | --help )
            echo "Usage: cuesplit [Path]"
            echo "       The default path is the current directory."
            exit 0
            ;;
        * )
        DIR=$1
    esac
fi

echo -e "\

Directory: $DIR
________________________________________
"
#https://github.com/koalaman/shellcheck/wiki/SC2164
cd "$DIR" || exit 65
TYPE=`ls -t1`

case $TYPE in
    *.ape*)
        mkdir split
        shnsplit -d split -f *.cue -o "flac flac -V --best -o %f -" *.ape -t "%n %p - %t"
        rm -f split/00*pregap*
        #cuetag.sh *.cue split/*.flac
        mv split/* .
        rm -r split
        exit 0
        ;;

    *.flac*)
        mkdir split
        shnsplit -d split -f *.cue -o "flac flac -V --best -o %f -" *.flac -t "%n %p - %t"
        rm -f split/00*pregap*
        #cuetag.sh *.cue split/*.flac
        mv split/* .
        rm -r split
        exit 0
        ;;

    *.mp3*)
        mp3splt -no "@n @p - @t (split)" -c *.cue *.mp3
        #cuetag.sh *.cue *split\).mp3
        exit 0
        ;;

    *.ogg*)
        mp3splt -no "@n @p - @t (split)" -c *.cue *.ogg
        #cuetag.sh *.cue *split\).ogg
        exit 0
        ;;

    *.tta*)
        mkdir split
        shnsplit -d split -f *.cue -o "flac flac -V --best -o %f -" *.tta -t "%n %p - %t"
        rm -f split/00*pregap*
        #cuetag.sh *.cue split/*.flac
        exit 0
        ;;

    *.wv*)
        mkdir split
        shnsplit -d split -f *.cue -o "flac flac -V --best -o %f -" *.wv -t "%n %p - %t"
        rm -f split/00*pregap*
        #cuetag.sh *.cue split/*.flac
        exit 0
        ;;

    *.wav*)
        mkdir split
        shnsplit -d split -f *.cue -o "flac flac -V --best -o %f -" *.wav -t "%n %p - %t"
        rm -f split/00*pregap*
        #cuetag.sh *.cue split/*.flac
        exit 0
        ;;

    * )
    echo "Error: Found no files to split!"
    echo "       --> APE, FLAC, MP3, OGG, TTA, WV, WAV"
    exit 65
esac
exit 0
