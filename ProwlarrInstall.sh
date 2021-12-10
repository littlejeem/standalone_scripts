#!/bin/bash
### Description: Prowlarr Debian install
### Originally from the Radarr Community

set -euo pipefail

# Am I root?, need root!
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit
fi
# Const
### Update these variables as required for your specific instance
app="prowlarr"                       # App Name
app_uid="prowlarr"                   # {Update me if needed} User App will run as and the owner of it's binaries
app_guid="media"                  # {Update me if needed} Group App will run as.
app_port="9696"                      # Default App Port; Modify config.xml after install if needed
app_prereq="curl sqlite3"            # Required packages
app_umask="0002"                     # UMask the Service will run as
app_bin=${app^}                      # Binary Name of the app
bindir="/opt/${app^}"                # Install Location
branch="develop"                     # {Update me if needed} branch to install
datadir="/var/lib/prowlarr/"         # {Update me if needed} AppData directory to use

# Create User / Group as needed
if ! getent group "$app_guid" >/dev/null; then
  groupadd "$app_guid"
  echo "Group [$app_guid] created"
fi
if ! getent passwd "$app_uid" >/dev/null; then
  adduser --system --no-create-home --ingroup "$app_guid" "$app_uid"
  echo "User [$app_uid] created and added to Group [$app_guid]"
else
  echo "User [$app_uid] already exists"
fi

if getent group $app_guid | grep -q "\b${app_uid}\b"; then
  echo "User [$app_uid] did not exist in Group [$app_guid]"
  usermod -a -G $app_guid $app_uid
  echo "Added User [$app_uid] to Group [$app_guid]"
fi

# Stop the App if running
if service --status-all | grep -Fq "$app"; then
    systemctl stop $app
    systemctl disable $app.service
fi
# Create Appdata Directory
# AppData
mkdir -p $datadir
chown -R $app_uid:$app_uid $datadir
chmod 775 $datadir
# Download and install the App
# prerequisite packages
apt install $app_prereq
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
cat << EOF | tee /etc/systemd/system/$app.service >/dev/null
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
# Exit
exit 0
