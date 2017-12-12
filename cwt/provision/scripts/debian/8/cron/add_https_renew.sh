#!/usr/bin/env bash

##
# Letsencrypt renew HTTPS certificate (certbot) cron setup.
#
# Run as root or sudo.
#
# Usage :
# $ . cwt/provision/scripts/debian/8/cron/add_https_renew.sh
#

. cwt/env/load.sh

CRON_FILE='/etc/crontab'
COMMENT="Run Letsencrypt's certbot renew every day at 00h52 and 12h52"

# Prevent risking adding the same line several times.
if grep -R "$COMMENT" $CRON_FILE
then
  echo "ERROR : Cron entry '$COMMENT' already exists in $CRON_FILE."
  echo "Aborting."
  return
fi

echo "
# $COMMENT.
52 0,12 * * *  root  certbot renew" >> $CRON_FILE

echo "Cron entry '$COMMENT' has been added to $CRON_FILE."
