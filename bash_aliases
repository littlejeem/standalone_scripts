#+--------------+
#+ INSTALLATION +
#+--------------+
# needs to be saved to ~/.bash_aliases
# so cp ~/bin/myscripts/standalone_scripts/bash_aliases ~/.bash_aliases
# OR
# ln -s /home/jlivin25/bin/standalone_scripts/bash_aliases /home/jlivin25/.bash_aliases
#
#version="0.3"
alias sized='sudo du -h --max-depth=1 | sort -hr'

alias la='ls -lsha'

alias update_all='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'

alias update_kodi='sudo apt update && sudo apt upgrade kodi-x11 -y && sudo apt autoremove -y'

alias os_info='sudo lsb_release -a && Kernel=$(uname -r) && echo "Kernel is: $Kernel" '

alias graphics_info='lspci -k | grep -EA3 "VGA|3D|Display" && nvidia-settings --version'

alias refresh='sudo shutdown -r now'

alias watch_log='tail -f /var/log/syslog'

alias watch_kodilog='tail -f ~/.kodi/temp/kodi.log'

alias print_log='cat /var/log/syslog'

alias print_kodilog='cat ~/.kodi/temp/kodi.log'

alias search_log='read name && grep $name /var/log/syslog'

alias search_kodilog='read name && grep $name ~/.kodi/temp/kodi.log'

alias calibre_add='read name && xvfb-run calibredb add /mnt/usbstorage/ebooks/"$name" --with-library http://localhost:8180'

alias ipinfo='wget -qO- https://ipinfo.io'

alias wanip='dig @resolver4.opendns.com myip.opendns.com +short'

alias wanip4='dig @resolver4.opendns.com myip.opendns.com +short -4'

alias wanip6='dig @resolver1.ipv6-sandbox.opendns.com AAAA myip.opendns.com +short -6'

alias kodi_version="grep Kodi .kodi/temp/kodi.log | head -1 | cut -d '(' -f 2 | cut -d ' ' -f 1"

alias motherboard_info='sudo dmidecode -t baseboard' #ubuntu only

alias memory_info='grep MemTotal /proc/meminfo && sudo dmidecode --type 17'

alias cpu_memory='lscpu'

alias edit_backup='nano /etc/star_backup_settings.conf'

alias docker_down='docker compose -f ~/docker/docker-compose.yml down'

alias docker_pull='docker compose -f ~/docker/docker-compose.yml pull'

alias docker_up='docker compose -f ~/docker/docker-compose.yml up -d'

alias docker_clean1='docker image prune'

alias docker_clean2='docker system prune'

alias docker_clean3='docker volume prune'