#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2012 Oct 31
#
# Summary: The collection of scripts in this folder deal with the system-level
# customizations that have to be done after any installation or major upgrade.

# Scripts called from here normally operate on system files; this therefore
# requires superuser privileges.

# some scripts require ssh
apt-get install zsh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

"$DIR/keylayout.pl" &&" $DIR/system_keyboard.sh"
"$DIR/applekeyboard.sh"
"$DIR/apache.sh"
"$DIR/ssh.sh"
"$DIR/tmux.zsh"

# running as superuser may confuse the crontab
sudo -u $( whoami ) "$DIR/crontab.sh" 
