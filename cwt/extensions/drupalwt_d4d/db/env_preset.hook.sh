#!/usr/bin/env bash

##
# Implements hook -s 'db' -a 'env_preset' -v 'HOST_TYPE INSTANCE_TYPE PROVISION_USING'.
#
# This implementation provides generic default DB credentials for "normal"
# Drupal setups.
#
# For multi-site setups :
# @see cwt/extensions/drupalwt/db/env_preset.hook.sh
#

case "$DWT_MULTISITE" in false)
  DB_HOST='mariadb'
  DB_NAME='drupal'
  DB_USER='drupal'
  DB_TABLES_SKIP_DATA='cache,cache_*,history,search_*,sessions,watchdog'
esac
