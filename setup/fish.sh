#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2013 Feb 27
#
# Summary: Install fishfish

# Identify the version of fish installed by the package manager
VERSION=$( apt-cache showpkg fish | grep -A1 Versions: | grep -o "^[0-9]*\(\.[0-9]*\)\?" )

if [[ $( echo "$VERSION >= 2" | bc -q ) == 1 ]]
then
   apt-get install fish
else
   echo -en "\e[0;31m"
   echo "fish via apt-get ($VERSION) is too old. Installing head from github"
   echo -en "\e[0m"

   apt-get install g++ autoconf git doxygen libncurses5-dev

   git clone git://github.com/fish-shell/fish-shell.git /tmp/fish-shell
   cd /tmp/fish-shell

   autoconf
   ./configure
   make
   make install

   echo "/usr/local/bin/fish" >> /etc/shells
fi

mkdir ~/temp/ # some fish config scripts depend on this directory
chsh -s /usr/local/bin/fish pconley
