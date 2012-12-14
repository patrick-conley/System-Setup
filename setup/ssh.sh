#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2012 Oct 31
#
# Summary: Install and set up ssh

apt-get install ssh

# Require public key authentication
sed -i /etc/ssh/sshd_config \
   -e "s/\(#\s*\)\?\(ChallengeResponseAuthentication\) \(yes\|no\)/\2 no/" \
   -e "s/\(#\s*\)\?\(PasswordAuthentication\) \(yes\|no\)/\2 no/" \
   -e "s/\(#\s*\)\?\(UsePAM\) \(yes\|no\)/\2 no/" 
