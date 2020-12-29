#+--------------+
#+ INSTALLATION +
#+--------------+
# needs to be saved to ~/.bash_aliases
# so cp ~/bin/myscripts/standalone_scripts/bash_aliases ~/.bash_aliases
#
alias sized='du -h --max-depth=1 | sort -hr'

alias la='ls -lsha'

alias update_all='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'

alias update_kodi='sudo apt update && sudo apt upgrade kodi-x11 -y && sudo apt autoremove -y'

alias os_info='sudo lsb_release -a && Kernel=$(uname -r) && echo "Kernel is: $Kernel" '
