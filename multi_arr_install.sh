#!/usr/bin/env bash
#
###############################################################################################
###                                          "INFO"                                         ###
### A sript to automate the necessary steps to install the multiple *arr's on a new system  ###
### None of this work is my own, full credit and correct up-to-date scripts here:           ###
### https://wiki.servarr.com/install-script                                                 ###
### I thought at the time of writing this that there was no combined script,                ###
### now i've just done it so I now how i might.                                             ###
###############################################################################################
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
version=0.3
#
#
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
# Source helper_script
if [[ -f /usr/local/bin/helper_script.sh ]]; then
  source /usr/local/bin/helper_script.sh
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
   echo -e "\t-S Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify Verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   echo -e "\t-l Override install of lidarr"
   echo -e "\t-a Override install of radarr"
   echo -e "\t-r Override install of readarr"
   echo -e "\t-p Override install of prowlarr"
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
      edebug "Group [$app_guid] created"
  fi

  if ! getent passwd "$app_uid" &>/dev/null; then
      useradd --system --groups "$app_guid" "$app_uid"
      edebug "User [$app_uid] created and added to Group [$app_guid]"
  else
      edebug "User [$app_uid] already exists"
  fi

  if ! getent group "$app_guid" |& grep -qw "${app_uid}" &>/dev/null; then
      edebug "User [$app_uid] did not exist in Group [$app_guid]"
      usermod -a -G "$app_guid" "$app_uid"
      edebug "Added User [$app_uid] to Group [$app_guid]"
  else
      edebug "User [$app_uid] already exists in Group [$app_guid]"
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
  DEBIAN_FRONTEND=noninteractive apt-get install -qq $app_prereq < /dev/null > /dev/null
  #apt install -y $app_prereq && apt autoremove -y
  ARCH=$(dpkg --print-architecture)
  # get arch
  dlbase="https://$app.servarr.com/v1/update/$branch/updatefile?os=linux&runtime=netcore"
  case "$ARCH" in
  "amd64") DLURL="${dlbase}&arch=x64" ;;
  "armhf") DLURL="${dlbase}&arch=arm" ;;
  "arm64") DLURL="${dlbase}&arch=arm64" ;;
  *)
      eerror "Arch not supported"
      exit 66
      ;;
  esac
  edebug "Downloading..."
  wget -q --content-disposition "$DLURL"
  tar -xzf ${app^}.*.tar.gz
  edebug "Installation files downloaded and extracted"
  # remove existing installs
  edebug "Removing existing installation"
  rm -rf $bindir
  edebug "Installing..."
  mv "${app^}" /opt/
  chown $app_uid:$app_uid -R $bindir
  rm -rf "${app^}.*.tar.gz"
  # Ensure we check for an update in case user installs older version or different branch
  touch $datadir/update_required
  chown $app_uid:$app_guid $datadir/update_required
  edebug "App Installed"
  # Configure Autostart
  # Remove any previous app .service
  edebug "Removing old service file"
  rm -rf /etc/systemd/system/$app.service
  # Create app .service with correct user startup
  edebug "Creating service file"
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
  edebug "Service file created. Attempting to start the app"
  systemctl -q daemon-reload
  systemctl enable --now -q "$app"
  # Finish Update/Installation
  host=$(hostname -I)
  ip_local=$(grep -oP '^\S*' <<<"$host")
  edebug "${app^} install complete"
  enotify "Browse to http://$ip_local:$app_port for the ${app^} GUI"
}
#
#
#+------------------------+
#+---"Get User Options"---+
#+------------------------+
while getopts ":SVGlarpHh" opt
do
    case "${opt}" in
        S) verbosity=$silent_lvl
        edebug "-S specified: Silent mode";;
        V) verbosity=$inf_lvl
        edebug "-V specified: Verbose mode";;
        G) verbosity=$dbg_lvl
        edebug "-G specified: Debug mode";;
        l) lidarr_override=1
        edebug "-l specified: skipping lidarr install";;
        a) radarr_override=1
        edebug "-l specified: skipping radarr install";;
        r) readarr_override=1
        edebug "-l specified: skipping readarr install";;
        p) prowlarr_override=1
        edebug "-p specified: skipping prowlarr install";;
        H) helpFunction;;
        h) helpFunction;;
        ?) helpFunction;;
    esac
done
#
#
#+-----------------+
#+---Main Script---+
#+-----------------+
esilent "$lockname started"
#
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null
#
if [[ -z $lidarr_override ]]; then
  edebug "installing lidarr"
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
fi
#
if [[ -z $lidarr_override ]]; then
  edebug "installing radarr"
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
fi
#
if [[ -z $lidarr_override ]]; then
  edebug "installing readarr"
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
fi
#
if [[ -z $lidarr_override ]]; then
  edebug "installing prowlarr"
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
fi
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
