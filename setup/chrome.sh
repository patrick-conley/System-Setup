#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 0000 xxx 00
#
# Summary: Install chrome and the Google PPA

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

echo "deb http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee -a /etc/apt/sources.list.d/google.list

sudo apt-get update
sudo apt-get install google-chrome-stable
