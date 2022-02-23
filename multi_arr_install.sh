#!/usr/bin/env bash
#
############################################################################################################
###                                                 "INFO"                                               ###
### A sript to automate the necessary steps to install control_scripts, put items in necessary locations ###
### for the first time running of scripts in other repository's such as sync_scripts/MusicSync.sh        ###
### Its vital that the locations have
############################################################################################################
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
#+------------------------------+
#+---"Set Special Parameters"---+
#+------------------------------+
set -euo pipefail
#
#
#+----------------------+
#+---"Check for Root"---+
#+----------------------+
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi
#
#
#+------------------------------+
#+---"Set script name & Info"---+
#+------------------------------+
# imports the name of this script
# failure to to set this as lockname will result in check_running failing and 'hung' script
# manually set this if being run as child from another script otherwise will inherit name of calling/parent script
scriptlong=`basename "$0"`
lockname=${scriptlong::-3} # reduces the name to remove .sh
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
#
#set default logging level
verbosity=3
version=0.1
#
#
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
# Source helper_script
if [[ -f /usr/local/bin/helper_script.sh ]]; then
  edebug "helper script located, using"
else
  echo "no helper_script located, exiting. Please install or check location"
  exit 66
fi
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
   echo "Usage: $0 -V selects dry-run with verbose level logging"
   echo -e "\t-d Use this flag to specify dry run, no files will be converted, useful in conjunction with -V or -G "
   echo -e "\t-S Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify Verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   echo -e "\t-p Specifically choose to install postfix prior to attempting to install abcde as its a requirement"
   echo -e "\t-u Use this flag to specify a user to install scripts under, eg. user foo is entered -u foo, as i made these scripts for myself the defualt user is my own"
   echo -e "\t-g Use this flag to specify a usergroup to install scripts under, eg. group bar is entered -g bar, combined with the -u flag these settings will be used as: chown foo:bar. As i made these scripts for myself the defualt group is my own"
   echo -e "\t-d Use this flag to specify the identity of the CD/DVD/BLURAY drive being used, eg. /dev/sr1 is entered -d sr1, sr0 will be the assumed default "
   echo -e "\t Running the script with no flags causes default behaviour with logging level set via 'verbosity' variable"
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
main_install () {
  # Create User / Group as needed
  if ! getent group "$app_guid" &>/dev/null; then
      groupadd "$app_guid"
      echo "Group [$app_guid] created"
  fi

  if ! getent passwd "$app_uid" &>/dev/null; then
      useradd --system --groups "$app_guid" "$app_uid"
      echo "User [$app_uid] created and added to Group [$app_guid]"
  else
      echo "User [$app_uid] already exists"
  fi

  if ! getent group "$app_guid" |& grep -qw "${app_uid}" &>/dev/null; then
      echo "User [$app_uid] did not exist in Group [$app_guid]"
      usermod -a -G "$app_guid" "$app_uid"
      echo "Added User [$app_uid] to Group [$app_guid]"
  else
      echo "User [$app_uid] already exists in Group [$app_guid]"
  fi

  # Stop the App if running
  if service --status-all | grep -Fq "$app"; then
      systemctl stop $app
      systemctl disable $app.service
  fi
  # Create Appdata Directory
  # AppData
  mkdir -p $datadir
  chown -R $app_uid:$app_guid $datadir
  chmod 775 $datadir
  # Download and install the App
  # prerequisite packages
  apt install -y $app_prereq && apt autoremove -y
  ARCH=$(dpkg --print-architecture)
  # get arch
  dlbase="https://$app.servarr.com/v1/update/$branch/updatefile?os=linux&runtime=netcore"
  case "$ARCH" in
  "amd64") DLURL="${dlbase}&arch=x64" ;;
  "armhf") DLURL="${dlbase}&arch=arm" ;;
  "arm64") DLURL="${dlbase}&arch=arm64" ;;
  *)
      echo_error "Arch not supported"
      exit 1
      ;;
  esac
  echo "Downloading..."
  wget --content-disposition "$DLURL"
  tar -xvzf ${app^}.*.tar.gz
  echo "Installation files downloaded and extracted"
  # remove existing installs
  echo "Removing existing installation"
  rm -rf $bindir
  echo "Installing..."
  mv "${app^}" /opt/
  chown $app_uid:$app_uid -R $bindir
  rm -rf "${app^}.*.tar.gz"
  # Ensure we check for an update in case user installs older version or different branch
  touch $datadir/update_required
  chown $app_uid:$app_guid $datadir/update_required
  echo "App Installed"
  # Configure Autostart
  # Remove any previous app .service
  echo "Removing old service file"
  rm -rf /etc/systemd/system/$app.service
  # Create app .service with correct user startup
  echo "Creating service file"
  cat <<- EOF | tee /etc/systemd/system/$app.service >/dev/null
  [Unit]
  Description=${app^} Daemon
  After=syslog.target network.target
  [Service]
  User=$app_uid
  Group=$app_guid
  UMask=$app_umask
  Type=simple
  ExecStart=$bindir/$app_bin -nobrowser -data=$datadir
  TimeoutStopSec=20
  KillMode=process
  Restart=always
  [Install]
  WantedBy=multi-user.target
EOF
  # Start the App
  echo "Service file created. Attempting to start the app"
  systemctl -q daemon-reload
  systemctl enable --now -q "$app"
  # Finish Update/Installation
  host=$(hostname -I)
  ip_local=$(grep -oP '^\S*' <<<"$host")
  echo ""
  echo "Install complete"
  echo "Browse to http://$ip_local:$app_port for the ${app^} GUI"
}
#
#
#+-----------------+
#+---Main Script---+
#+-----------------+
#install lidarr
app="lidarr"                        # App Name
app_uid="lidarr"                    # {Update me if needed} User App will run as and the owner of it's binaries
app_guid="media"                    # {Update me if needed} Group App will run as.
app_port="8686"                     # Default App Port; Modify config.xml after install if needed
app_prereq="curl mediainfo sqlite3 libchromaprint-tools"            # Required packages
app_umask="0002"                    # UMask the Service will run as
app_bin=${app^}                     # Binary Name of the app
bindir="/opt/${app^}"               # Install Location
branch="master"                     # {Update me if needed} branch to install
datadir="/var/lib/lidarr/"          # {Update me if needed} AppData directory to use
main_install
#
#install radarr
app="radarr"                        # App Name
app_uid="radarr"                    # {Update me if needed} User App will run as and the owner of it's binaries
app_guid="media"                    # {Update me if needed} Group App will run as.
app_port="7878"                     # Default App Port; Modify config.xml after install if needed
app_prereq="curl mediainfo sqlite3" # Required packages
app_umask="0002"                    # UMask the Service will run as
app_bin=${app^}                     # Binary Name of the app
bindir="/opt/${app^}"               # Install Location
branch="master"                     # {Update me if needed} branch to install
datadir="/var/lib/radarr/"          # {Update me if needed} AppData directory to use
main_install
#
#install readarr
app="readarr"                       # App Name
app_uid="readarr"                   # {Update me if needed} User App will run as and the owner of it's binaries
app_guid="media"                    # {Update me if needed} Group App will run as.
app_port="8787"                     # Default App Port; Modify config.xml after install if needed
app_prereq="curl sqlite3"           # Required packages
app_umask="0002"                    # UMask the Service will run as
app_bin=${app^}                     # Binary Name of the app
bindir="/opt/${app^}"               # Install Location
branch="nightly"                    # {Update me if needed} branch to install
datadir="/var/lib/readarr/"         # {Update me if needed} AppData directory to use
main_install
#
#install prowlarr
app="prowlarr"                      # App Name
app_uid="prowlarr"                  # {Update me if needed} User App will run as and the owner of it's binaries
app_guid="media"                    # {Update me if needed} Group App will run as.
app_port="9696"                     # Default App Port; Modify config.xml after install if needed
app_prereq="curl sqlite3"           # Required packages
app_umask="0002"                    # UMask the Service will run as
app_bin=${app^}                     # Binary Name of the app
bindir="/opt/${app^}"               # Install Location
branch="develop"                    # {Update me if needed} branch to install
datadir="/var/lib/prowlarr/"        # {Update me if needed} AppData directory to use
main_install
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
#
exit 0
