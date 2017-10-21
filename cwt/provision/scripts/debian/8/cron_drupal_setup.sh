#!/bin/bash

##
# LAMP server Drupal cron setup.
#
# Run as root or sudo.
#
# Usage :
# $ . cwt/stack/lamp_deb/cron_drupal_setup.sh
#

. cwt/env/load.sh

CRON_FILE='/etc/crontab'
COMMENT="Run Drupal's cron for $INSTANCE_DOMAIN ($INSTANCE_TYPE) every 30 min using drush"

# Prevent risking adding the same line several times.
if grep -R "$COMMENT" $CRON_FILE
then
  echo "ERROR : Cron entry '$COMMENT' already exists in $CRON_FILE."
  echo "Aborting."
  return
fi

echo "
# $COMMENT.
*/30 * * * *  root  drush --root=$APP_DOCROOT cron" >> $CRON_FILE

echo "Cron entry '$COMMENT' has been added to $CRON_FILE."
