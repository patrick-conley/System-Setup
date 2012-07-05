#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2012 Jul 05
#
# Summary: Set up a default crontab, calling batch_unison.sh (hourly),
# podcaster.pl (weekly)

if [[ -n $( crontab -l ) ]]
then
   echo "Can't set the crontab. One already exists for $( whoami )"
   exit 1
fi

# m h  dom mon dow   command

crontab - <<EOT
$(( $RANDOM % 60 )) * * * * /home/pconley/bin/sync/batch_unison.sh -t 1
$(( $RANDOM % 60 )) 15 * * 0 podcaster.pl
EOT

echo "Successfully added crontab items"
