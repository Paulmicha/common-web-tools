#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'destroy' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Deletes VHost potentially generated for this local instance.
#

if [[ -L "/etc/apache2/sites-enabled/${INSTANCE_DOMAIN}.conf" ]]; then
  if i_am_su; then
    a2dissite "$INSTANCE_DOMAIN"
  else
    sudo a2dissite "$INSTANCE_DOMAIN"
  fi
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to deactivate Apache vhost '/etc/apache2/sites-available/${INSTANCE_DOMAIN}.conf'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
  if i_am_su; then
    apache2_reload
  else
    sudo apache2_reload
  fi
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to reload Apache configuration'." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
fi

if [[ -f "/etc/apache2/sites-available/${INSTANCE_DOMAIN}.conf" ]]; then
  if i_am_su; then
    rm "/etc/apache2/sites-available/${INSTANCE_DOMAIN}.conf"
  else
    sudo rm "/etc/apache2/sites-available/${INSTANCE_DOMAIN}.conf"
  fi
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Notice in $BASH_SOURCE line $LINENO: unable to delete the Apache VHost file '/etc/apache2/sites-available/${INSTANCE_DOMAIN}.conf'." >&2
    echo "You'll have to remove it manually." >&2
    echo >&2
  fi
fi
