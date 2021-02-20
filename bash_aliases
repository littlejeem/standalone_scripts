#+--------------+
#+ INSTALLATION +
#+--------------+
# needs to be saved to ~/.bash_aliases
# so cp ~/bin/myscripts/standalone_scripts/bash_aliases ~/.bash_aliases
#
alias sized='du -h --max-depth=1 | sort -hr' #<---Can also be used with sudo for protected folders

alias la='ls -lsha'

alias update_all='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'

alias update_kodi='sudo apt update && sudo apt upgrade kodi-x11 -y && sudo apt autoremove -y'

alias os_info='sudo lsb_release -a && Kernel=$(uname -r) && echo "Kernel is: $Kernel" '

alias graphics='lspci | grep VGA'

alias refresh='sudo shutdown -r now'

alias watch_log='tail -f /var/log/syslog'

alias print_log='cat /var/log/syslog'

alias edit_log='nano /var/log/syslog'

alias search_log='read name && grep $name /var/log/syslog'

alias calibre_add='read name && xvfb-run calibredb add /mnt/usbstorage/ebooks/"$name" --with-library http://localhost:8180'
