#!/usr/bin/env bash

##
# LAMP server Apache VHost deletion.
#
# Run as root or sudo.
#
# Usage (replace example domain + optional alias passed as arguments) :
# $ . cwt/provision/scripts/debian/8/vhost_remove.sh the-domain.com
#

. cwt/env/load.sh

# Require 1st argument.
if [[ -z ${1} ]]; then
  echo "ERROR : domain (1st argument) is required."
  echo "Example : \$ . cwt/provision/scripts/debian/8/vhost_remove.sh the-domain.com"
  return
fi


DOMAIN=${1}
VHOST_FILE="/etc/apache2/sites-available/${DOMAIN}.conf"

if [ ! -f $HTTPS_VHOST_FILE ]; then
  echo "ERROR : file $HTTPS_VHOST_FILE does not exist."
  return
fi

echo "Disabling $DOMAIN ..."
a2dissite $DOMAIN
echo "Deleting $VHOST_FILE ..."
rm $VHOST_FILE


HTTPS_DOMAIN="${DOMAIN}-le-ssl"
HTTPS_VHOST_FILE="/etc/apache2/sites-available/${HTTPS_DOMAIN}.conf"

if [ -f $HTTPS_VHOST_FILE ]; then
  echo "Disabling $HTTPS_DOMAIN ..."
  a2dissite $HTTPS_DOMAIN
  echo "Deleting $HTTPS_VHOST_FILE ..."
  rm $HTTPS_VHOST_FILE
fi


echo "Reloading Apache config ..."
service apache2 reload


echo "Done."
