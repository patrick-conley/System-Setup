#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2012 May 04
#
# Summary: The collection of scripts in this folder deal with the system-level
# customizations that have to be done after any installation or major upgrade.

# Scripts called from here normally operate on system files; this therefore
# requires superuser privileges.

./keylayout.pl && ./system_keyboard.sh
./applekeyboard.sh
./apache.sh
sudo -u $( whoami ) ./crontab.sh # running as superuser may confuse the crontab
