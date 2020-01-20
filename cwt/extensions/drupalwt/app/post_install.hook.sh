#!/usr/bin/env bash

##
# Implements hook -p 'post' -s 'app' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
#
# This file is dynamically included when the "hook" is triggered.
#
# Debug lookup paths (make sure this file gets picked up) :
# To list all the possible paths that can be used among which existing files
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:app p:pre a:install v:PROVISION_USING INSTANCE_TYPE
# $ make hook-debug s:app a:install v:PROVISION_USING INSTANCE_TYPE
# $ make hook-debug s:app p:post a:install v:PROVISION_USING INSTANCE_TYPE
#
# @example
#   make app-install
#   # Or :
#   cwt/app/install.sh
#

# Provide default cron job implementation for this Drupal instance on local host
# using crontab. This setup is opt-in, i.e. the DWT_USE_CRONTAB global.
# @see cwt/extensions/drupalwt/global.vars.sh
# @see cwt/extensions/drupalwt/app/global.vars.sh
# @see u_host_crontab_add() in cwt/host/host.inc.sh
case "$DWT_USE_CRONTAB" in 1|y*|true)
  echo "Setup Drupal cron job for instance $INSTANCE_DOMAIN on local host ..."

  u_host_crontab_add "cd $PROJECT_DOCROOT && cwt/extensions/drupalwt/instance/drush.sh cron" "$DWT_CRON_FREQ"

  echo "Setup Drupal cron job for instance $INSTANCE_DOMAIN on local host : done."
  echo
esac
