#!/bin/bash
#
#
############################################################
### A script to automate manual install of ffmpeg        ###
### https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu ###
############################################################
#
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
#+----------------------+
#+---"Check for Root"---+
#+----------------------+
#only needed if root privaleges necessary, enable
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 66
fi
#
#
#+-----------------------+
#+---"Set script name"---+
#+-----------------------+
# imports the name of this script
# failure to to set this as lockname will result in check_running failing and 'hung' script
# manually set this if being run as child from another script otherwise will inherit name of calling/parent script
scriptlong=`basename "$0"`
lockname=${scriptlong::-3} # reduces the name to remove .sh
#
#
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
source /usr/local/bin/helper_script.sh
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
#set default logging level, failure to set this will cause a 'unary operator expected' error
#remember at level 3 and lower, only esilent messages show, best to include an override in getopts
verbosity=3
#
version="0.3" #
script_pid=$(echo $$)
stamp=$(echo "`date +%H.%M`-`date +%d_%m_%Y`")
#pushover_title="NAME HERE" #Uncomment if using pushover
#
#
#+---------------------------------------+
#+---"check if script already running"---+
#+---------------------------------------+
check_running
#
#
#+-------------------+
#+---Set functions---+
#+-------------------+
helpFunction () {
   echo ""
   echo "Usage: $0 $scriptlong"
   echo "Usage: $0 $scriptlong -G"
   echo -e "\t Running the script with no flags causes default behaviour with logging level set via 'verbosity' variable"
   echo -e "\t-S Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify Verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   echo -e "\t-u specifiy the install user to use"
   echo -e "\t-h -H Use this flag for help"
   if [ -d "/tmp/$lockname" ]; then
     edebug "removing lock directory"
     rm -r "/tmp/$lockname"
   else
     edebug "problem removing lock directory"
   fi
   exit 65 # Exit script after printing help
}
#
#
#+------------------------+
#+---"Get User Options"---+
#+------------------------+
OPTIND=1
while getopts ":SVGHh:u:" opt
do
    case "${opt}" in
        S) verbosity=$silent_lvl
        edebug "-S specified: Silent mode";;
        V) verbosity=$inf_lvl
        edebug "-V specified: Verbose mode";;
        G) verbosity=$dbg_lvl
        edebug "-G specified: Debug mode";;
        u) chosen_user=${OPTARG}
        edebug "-u specified: using $chosen_user";;
        H) helpFunction;;
        h) helpFunction;;
        ?) helpFunction;;
    esac
done
shift $((OPTIND -1))
#
#
#+----------------------+
#+---"Script Started"---+
#+----------------------+
# At this point the script is set up and all necessary conditions met so lets log this
esilent "$lockname started"
#
#
#+-------------------------------+
#+---Configure GETOPTS options---+
#+-------------------------------+
#e.g for a drive option
if [[ $install_user != "" ]]; then
  install_user=$(chosen_user)
  edebug "Install user set as: $install_user"
else
  install_user="$USER"
  edebug "Install user set as: $install_user"
fi
#
edebug "GETOPTS options set"
#
#
#+--------------------------+
#+---"Source config file"---+
#+--------------------------+
source /usr/local/bin/config.sh
#
#
#+--------------------------------------+
#+---"Display some info about script"---+
#+--------------------------------------+
edebug "Version of $scriptlong is: $version"
edebug "PID is $script_pid"
#
#
#+-------------------+
#+---Set up script---+
#+-------------------+
#Get environmental info
edebug "INVOCATION_ID is set as: $INVOCATION_ID"
edebug "EUID is set as: $EUID"
edebug "PATH is: $PATH"
#
#
#+----------------------------+
#+---"Main Script Contents"---+
#+----------------------------+
#GET AND INSTALL DEPENDANCIES
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
#
#CREATE NECESSARY DIRECTORIES IF NOT EXISTING
sudo -u $install_user mkdir -p /home/$install_user/ffmpeg_sources /home/$install_user/bin
#
#INSTALL THIRD-PARTY LIBRARIES
apt-get install -y nasm
apt-get install -y yasm
apt-get install -y libx264-dev
apt-get install -y libx265-dev
apt-get install -y libnuma-dev
apt-get install -y libvpx-dev
apt-get install -y libfdk-aac-dev
apt-get install -y libmp3lame-dev
#
#CONFIGURE & INSTALL FFMPEG TO INCLUDE EXTRA PACKAGES
cd /home/$install_user/ffmpeg_sources && \
sudo -u $install_user wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
sudo -u $install_user tar xjvf ffmpeg-snapshot.tar.bz2 && \
cd ffmpeg && sudo -u $install_user \
PATH="/home$install_user/bin:$PATH" PKG_CONFIG_PATH="/home$install_user/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="/home/$install_user/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I/home/$install_user/ffmpeg_build/include" \
  --extra-ldflags="-L/home/$install_user/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --bindir="/home/$install_user/bin" \
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
PATH="/home/$install_user/bin:$PATH" make -j2 && \
make -j2 install && \
hash -r
echo "now exit and relogin entering 'source ~/.profile'"
#
#
#+-------------------+
#+---"Script Exit"---+
#+-------------------+
rm -r /tmp/"$lockname"
if [[ $? -ne 0 ]]; then
    eerror "error removing lockdirectory"
    exit 65
else
    enotify "successfully removed lockdirectory"
fi
esilent "$lockname completed"
exit 0
