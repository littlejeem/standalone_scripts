#!/usr/bin/env bash
#
#A small script to prep a fresh environment for arrs on new system
#
#Adjust screen default output
#If ubuntu booting from a hard/ssd drive you'll need to use
#sudo nano /boot/firmware/usercfg.txt
#
cat << EOF
[HDMI:0] #two HDMI's on raspi4
hdmi_group=1 #1 for CEC (TV;s) 2 for monitors
hdmi_mode=16 #code for 1080p 60hz
hdmi_drive=2 #DVI or HDMI mode (2 is for sound over HDMI)

[HDMI:1]
hdmi_group=2
hdmi_mode=82
hdmi_drive=2
EOF

sudo nano /etc/ssh/sshd_config
#change sshd port from default 22 to customer 5008 or similar
sudo systemctl restart sshd.service

#exit ssh session and relogin with ssh -p 5008 hostdetails

#create group 'media' for all arr's, transmission and user to belong to
sudo groupadd media
sudo usermod -a -G media $USER

#set up necessary download location and folders, givng them correct permissions and to inherit permissions for new folders/fles created
sudo mkdir /mnt/usbstorage
if cd /mnt; then
  echo "Ok"
else
  echo "Fail"
  exit 1
fi
sudo chmod -R 775 usbstorage/
sudo chown -R $USER:media usbstorage/ #change $USER to the ssh user you use to log in
sudo chmod g+s usbstorage/

#format and mount the hard drive if necessary
#use sudo gdisk /dev/sda to take drive back to blank and create GPT file table then new file system
#then do
sudo mkfs.ext4 /dev/sda1
sudo mount -t ext4 /dev/sda1 /mnt/usbstorage

#now we create folders for stuff to use
if cd /mnt/usbstorage; then
  echo "Ok"
else
  echo "Fail"
  exit 1
fi
mkdir movies tv music ebooks audiobooks
mkdir -p download/complete/transmission && mkdir -p download/incomplete/transmission
if cd /mnt/usbstorage/download/complete/transmission; then
  echo "Ok"
else
  echo "Fail"
  exit 1
fi
mkdir RadarrMovies LidarrMusic SonarrTv ReadarrAudio ReadarrBooks

#create necessary users to sandbox but without home directory
# dont use either of these four lines if running the multi-install script
#sudo adduser --system --no-create-home --ingroup media radarr
#sudo adduser --system --no-create-home --ingroup media lidarr
#sudo adduser --system --no-create-home --ingroup media readarr
#sudo adduser --system --no-create-home --ingroup media prowlarr
#sudo useradd -r -s /bin/false radarr
#sudo useradd -r -s /bin/false lidarr
#sudo useradd -r -s /bin/false readarr
#sudo useradd -r -s /bin/false prowlarr
#sudo useradd -r -s /bin/false sonarr #curently done by package manager in ubuntu

# Install transmission at this point
sudo add-apt-repository ppa:transmissionbt/ppa
#
sudo apt-get update && sudo apt-get install transmission-cli transmission-common transmission-daemon -y
#
sudo systemctl stop transmission-daemon
#
l

#sudo sed -i  /var/lib/transmission-daemon/.config/transmission-daemon/settings.json

transmission_username="littlejeem"
transmission_password="madjim10"
transmission_partial="/mnt/usbstorage/download/incomplete/transmission"
transmission_download="/mnt/usbstorage/download/complete/transmission"
transmission_rpc_whitelist="127.0.0.*, 192.168.0.*"



if [[ -z $transmission_download ]] || [[ -z $transmission_username ]] || [[ -z $transmission_password ]] || [[ -z $transmission_rpc_whitelist ]]; then
  echo ""
fi
#add users to 'media' group, this step may be un-necessary if the 'adduser --system' lines can work, not needed if using install script
#sudo usermod -a -G media radarr
#sudo usermod -a -G media lidarr
#sudo usermod -a -G media readarr
#sudo usermod -a -G media prowlarr
#sudo usermod -a -G media sonarr

#create config folders for 'arr's & correct perms, dont use if using the multi-install
#sudo mkdir /var/lib/radarr && sudo chown radarr:media /var/lib/radarr
#sudo mkdir /var/lib/lidarr && sudo chown lidarr:media /var/lib/lidarr
#sudo mkdir /var/lib/readarr && sudo chown readarr:media /var/lib/readarr
#sudo mkdir /var/lib/prowlarr && sudo chown prowlarr:media /var/lib/prowlarr
#sudo mkdir /var/lib/sonarr && sudo chown sonarr:sonarr /var/lib/sonarr

mkdir ~/Downloads
if cd ~/Downloads; then
  echo "Ok"
else
  echo "Fail"
fi
#
#Use *arr developed install scripts from servarr
# INSTALL SONARR from its own guide
#download and run community installers for the others
#curl -o RadarrInstall.sh https://raw.githubusercontent.com/littlejeem/standalone_scripts/develop/RadarrInstall.sh
#curl -o ProwlarrInstall.sh https://raw.githubusercontent.com/littlejeem/standalone_scripts/develop/ProwlarrInstall.sh
#curl -o LidarrInstall.sh https://raw.githubusercontent.com/littlejeem/standalone_scripts/develop/LidarrInstall.sh
#curl -o ReadarrInstall.sh https://raw.githubusercontent.com/littlejeem/standalone_scripts/develop/ReadarrInstall.sh
curl -o multi_arr_install.sh https://raw.githubusercontent.com/littlejeem/standalone_scripts/develop/multi_arr_install.sh
#now run the install scripts
#sudo bash ProwlarrInstall.sh
#sudo bash RadarrInstall.sh
#sudo bash LidarrInstall.sh
#sudo bash ReadarrInstall.sh
sudo bash multi_arr_install.sh
#stop all services and edit transmission settings
sudo systemctl stop lidarr.service sonarr.service radarr.service prowlarr.service transmission-daemon.service
sudo nano /var/lib/transmission-daemon/info/settings.json
#change rpc bind, umask, simultaenous downloads, incomplete directory to true, change download and incomplete directory as necessary
###THIS IS THE POINT TO COPY ACCROSS APP .config backups but first backup old configs
sudo cp /var/lib/radarr/config.xml /var/lib/radarr/config.xml.backup
sudo cp /var/lib/sonarr/config.xml /var/lib/sonarr/config.xml.backup
sudo cp /var/lib/lidarr/config.xml /var/lib/lidarr/config.xml.backup
sudo cp /var/lib/prowlarr/config.xml /var/lib/prowlarr/config.xml.backup
#sudo mv /var/lib/readarr/config.xml /var/lib/readarr/config.xml.backup

#copy (eg ftp) the backups into your downloads folder in format $arrname_config.sh where $arrname is the arr config you are copying accross
if cd ~/Downloads; then
  echo "Ok"
else
  echo "Fail"
fi
sudo mv radarr_config.xml /var/lib/radarr/config.xml
sudo mv sonarr_config.xml /var/lib/sonarr/config.xml
sudo mv lidarr_config.xml /var/lib/lidarr/config.xml
sudo mv prowlarr_config.xml /var/lib/prowlarr/config.xml
#sudo mv /var/lib/readarr/config.xml /var/lib/readarr/config.xml.backup

#now navigate to the /var/lib/$arrname folder and check perms of the new config match old one
sudo chown ubuntu:media /var/lib/radarr/config.xml
sudo chown ubuntu:media /var/lib/sonarr/config.xml
sudo chown ubuntu:media /var/lib/lidarr/config.xml
sudo chown ubuntu:media /var/lib/prowlarr/config.xml
#sudo chown ubuntu:media /var/lib/readarr/config.xml

#restart the services
sudo systemctl start lidarr.service sonarr.service radarr.service prowlarr.service transmission-daemon.service

#check settings in the *arrs

#Set up VPN, so in this case NORDVPN
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
#Follow instructions online, then:
nordvpn whitelist add port 22 #your ssh port otherwise you are trapped out
nordvpn whitelist add port 5008 #your ssh port you changed above
nordvpn whitelist add port 9091
nordvpn whitelist add port 51413 protocol TCP
nordvpn whitelist add port 8989 protocol TCP
nordvpn whitelist add port 9696 protocol TCP
nordvpn whitelist add port 8686 protocol TCP
nordvpn whitelist add port 7878 protocol TCP
nordvpn whitelist add port 9393 protocol TCP #
nordvpn whitelist add port 51413 protocol TCP
nordvpn whitelist add port 5223 protocol TCP # Pushover iOS devices
nordvpn whitelist add port 5228 protocol TCP # Pushover Android devices
nordvpn whitelist add port 443 protocol TCP # Pushover Desktop devices
nordvpn login #you will get given a URL to follow, follow this on your laptop when the page completes. Copy the link in the 'continue' button and paste INSIDE the quotes below.
nordvpn login --callback "URL"
nordvpn connect P2P
nordvpn set autoconnect enabled
nordvpn set killswitch enabled
