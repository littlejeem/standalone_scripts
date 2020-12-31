#!/usr/bin/env bash
#
assigned_user="jlivin25"
dir_name="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#
#+------------------------------------+
#+---"Test for root running script"---+
#+------------------------------------+
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi
#
#
#+------------------------+
#+---"Install main app"---+
#+------------------------+
apt update
apt install python-dev python-pip -y
sudo -u $assigned_user pip install --user beets
#
#
#+----------------------------------------+
#+---"Install dependancies for plugins"---+
#+----------------------------------------+
# chroma
sudo -u $assigned_user pip install pyacoustid
sudo -u $assigned_user pip install gmusicapi
apt install -y libchromaprint-tools
#
#
#+--------------------------------+
#+---"Set up default locations"---+
#+--------------------------------+
# conversion destinations
sudo -u $assigned_user mkdir -p $HOME/Music/Library/alacimports
sudo -u $assigned_user mkdir -p $HOME/Music/Library/flacimports
sudo -u $assigned_user mkdir -p $HOME/Music/Library/PlayUploads
# library file sources
sudo -u $assigned_user mkdir -p $HOME/.config/ScriptSettings/beets/alac
sudo -u $assigned_user mkdir -p $HOME/.config/ScriptSettings/beets/flac
sudo -u $assigned_user mkdir -p $HOME/.config/ScriptSettings/beets/uploads
#
#
#+-------------------------+
#+---"Copy config files"---+
#+-------------------------+
sudo -u $assigned_user cp $HOME/bin/control_scripts/beets_configs/alac_config.yaml $HOME/.config/ScriptSettings/beets/alac/
sudo -u $assigned_user cp $HOME/bin/control_scripts/beets_configs/flac_config.yaml $HOME/.config/ScriptSettings/beets/flac/
sudo -u $assigned_user cp $HOME/bin/control_scripts/beets_configs/uploads_config.yaml $HOME/.config/ScriptSettings/beets/uploads/
#
#
