#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2011 Dec 29
#
# Summary: Change the function-lock status for any apple keyboards installed
#
# Based on https://help.ubuntu.com/community/AppleKeyboard

echo "options hid_apple fnmode=2" >> /etc/modprobe.d/hid_apple.conf
sudo update-initramfs -u

if [[ -d /sys/module/hid_apple ]]
then
   echo 2 > /sys/module/hid_apple/parameters/fn_mode
fi
