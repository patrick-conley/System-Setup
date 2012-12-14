#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2011 Dec 29
#
# Summary: Install Apache and set up UserDir

userdir='www'

apt-get -y install apache2 php5
apachectl restart

a2enmod userdir
sed -i -e "s/UserDir [^\s]*$/UserDir $userdir/" -e "s/<Directory .*>/<Directory \/home\/*\/$userdir>/" /etc/apache2/mods-enabled/userdir.conf
/etc/init.d/apache2 restart
