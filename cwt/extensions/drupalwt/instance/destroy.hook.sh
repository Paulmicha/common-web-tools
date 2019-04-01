#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'destroy' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# This file is dynamically included when the "hook" is triggered.
#
# Debug lookup paths (make sure this file gets picked up) :
# $ make hook-debug s:instance a:destroy v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# @example
#   make destroy
#   # Or :
#   cwt/instance/destroy.sh
#

. cwt/bootstrap.sh

echo "Cleanup any potential Drupal cron job for instance $INSTANCE_DOMAIN on local host ..."

# @see cwt/extensions/drupalwt/app/install.hook.sh
u_host_crontab_remove "cd $PROJECT_DOCROOT && make drush cron"

echo "Cleanup any potential Drupal cron job for instance $INSTANCE_DOMAIN on local host : done."
echo
