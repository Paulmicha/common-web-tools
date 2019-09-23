#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'destroy' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Deletes VHost potentially generated for this local instance.
#

if [[ -L "/etc/apache2/sites-enabled/${INSTANCE_DOMAIN}.conf" ]]; then
  a2dissite "$INSTANCE_DOMAIN"
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to deactivate Apache vhost '/etc/apache2/sites-available/${INSTANCE_DOMAIN}.conf'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
  apache2_reload
fi

if [[ -f "/etc/apache2/sites-available/${INSTANCE_DOMAIN}.conf" ]]; then
  rm "/etc/apache2/sites-available/${INSTANCE_DOMAIN}.conf"
fi
