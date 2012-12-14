#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2011 Dec 29
#
# Summary: Set the system keyboard layout to pDvorak. This should absolutely
# only be done on a system only I use

sed -i -e 's/XKBLAYOUT=.*/XKBLAYOUT="pconley"/' -e 's/XKBVARIANT=.*/XKBVARIANT=""/' /etc/default/keyboard
