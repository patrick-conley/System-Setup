#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2013 Feb 27
#
# Summary: Install fishfish

apt-get install g++ autoconf git doxygen libncurses5-dev

git clone git://github.com/fish-shell/fish-shell.git /tmp/fish-shell
cd /tmp/fish-shell

autoconf
./configure
make
make install

echo "/usr/local/bin/fish" >> /etc/shells
chsh -s /usr/local/bin/fish pconley
