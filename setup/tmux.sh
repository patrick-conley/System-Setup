#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2012 Dec 13
#
# Summary: Install tmux v. 1.7

# Identify the version of tmux installed by the package manager
VERSION=$( apt-cache showpkg tmux | grep -A1 Versions: | grep -o "^[0-9\.]*" )

if [[ $( echo "$VERSION >= 1.7" | bc -q ) == 1 ]]
then
   apt-get install tmux 
   exit 0
else
   echo -en "\e[0;31m"
   echo "tmux via apt-get ($VERSION) is too old. Installing manually"
   echo -en "\e[0m"
fi

# install dependencies
apt-get install -y libevent-dev libncurses5-dev

# install tmux
DL_PATH=$( mktemp )
SRC_DIR=$( mktemp -d )

wget "http://sourceforge.net/projects/tmux/files/latest/download?source=files" -O $DL_PATH

cd $SRC_DIR
tar -xf $DL_PATH
cd $(ls)

./configure && make install

