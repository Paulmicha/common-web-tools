#!/usr/bin/env bash

##
# Implements hook -s 'app' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
#
# This file is dynamically included when the "hook" is triggered.
#
# Debug lookup paths (make sure this file gets picked up) :
# $ make hook-debug s:app a:install v:PROVISION_USING INSTANCE_TYPE
#
# @example
#   make app-install
#   # Or :
#   cwt/app/install.sh
#

. cwt/bootstrap.sh

# Provide default cron job implementation for this Drupal instance on local host
# using crontab. This setup is opt-in, i.e. the D4D_USE_CRONTAB global.
# @see cwt/extensions/docker4drupal/global.vars.sh
# @see cwt/extensions/docker4drupal/app/global.vars.sh
# @see u_host_crontab_add() in cwt/host/host.inc.sh
case "$D4D_USE_CRONTAB" in 1|y|yes|true)
  echo "Setup Drupal cron job for instance $INSTANCE_DOMAIN on local host ..."

  u_host_crontab_add "cd $PROJECT_DOCROOT && make drush cron" "$DRUPAL_CRON_FREQ"

  echo "Setup Drupal cron job for instance $INSTANCE_DOMAIN on local host : done."
  echo
esac
